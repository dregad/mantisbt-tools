#!/usr/bin/python3 -u

# Processes the Supybot ChannelLogger's log directory and generates
# html pages for the IRC logs
# Assumes that the dir / log file names do not have a leading '#'

from datetime import datetime
from pathlib import Path
import re
import subprocess
import sys

# ---------------------------------------------------------------------

# Directory where ChannelLogger stores the raw IRC logs
source_dir = '/home/supybot/mantisbot/logs/ChannelLogger'

# Web server directory from which the html pages are served
target_dir = '/srv/www/irclogs'

# Regex for IRC logs archives to process
regexstr_channel = '^mantisbt$'

# ---------------------------------------------------------------------


def log(msg):
    """
    Prints log message with timestamp
    """
    print("{}  {}".format(
        datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        msg
    ))


def check_path(p):
    """
    Converts path to absolute and check that it exists
    """
    try:
        p = Path(p).resolve(strict=True)
    except FileNotFoundError:
        print("ERROR: %s is not a valid directory" % p)
        exit(1)
    return p


def run_logs2html(channel, source, target):
    """
    Runs the logs2html script for specified source directory and
    saves output in target.
    """

    msg = "IRC logs of #" + channel
    cmd = ["logs2html",
           "--title=" + msg,
           "--prefix=%s for " % msg,
           "--output-dir=" + str(target),
           str(source)
           ]

    print("generating html - %s" % " ".join(cmd))

    # Execute logs2html, redirect stderr to stdout for logging purposes
    subprocess.check_call(cmd, stderr=sys.stdout.fileno())


def convert_logs(source, target):
    """
    Process source path, convert all logs to html and save them in target
    """

    # Reference timestamp - 30 days ago
    ref_time = datetime.now().timestamp() - 86400 * 30

    # Building a list of channels to generate index page later
    channels = dict()

    # The directories in source are our logged channels
    for channel in sorted(Path(source).glob('*')):
        # Ignore regular files
        if not channel.is_dir():
            continue

        # Skip if channel not matching spec
        regex_channel = re.compile(regexstr_channel)
        if not regex_channel.match(channel.name):
            continue

        print("Processing channel #{} ".format(channel.name))
        channels[channel.name] = set()

        # One directory per year under the Channel dir
        years = Path(channel).glob('*')
        has_years = False
        for year in sorted(years):
            # Ignore regular files
            if not year.is_dir():
                continue

            has_years = True

            # Get the most recent log file's timestamp
            log_files = Path(year).glob('*.log')
            recent_log = max(log_files, key=lambda f: f.stat().st_mtime)
            recent_log_ts = recent_log.stat().st_mtime

            # Skip if not modified since reference timestamp
            if recent_log_ts < ref_time:
                continue

            print("\t{}:".format(year.name), end=' ')

            # Check that the html file corresponding to most recent log
            # exists and is actually newer than the log file
            html_target = Path(target).joinpath(year.relative_to(source))
            html_file = html_target.joinpath(
                recent_log.with_suffix('.log.html').name
            )
            if html_file.is_file() \
                    and recent_log_ts <= html_file.stat().st_mtime:
                print("up-to-date html exists for newest log file "
                      + recent_log.name)
                continue

            channels[channel.name].add(year.name)
            run_logs2html(channel.name, year, html_target)

        if has_years and not channels[channel.name]:
            print("\tLog files unchanged since {}".format(
                datetime.fromtimestamp(ref_time).strftime('%F')
            ))
        # No subdirs found = no yearly rotation setup, all files are here
        elif not has_years:
            print("\t:", end=' ')
            run_logs2html(channel.name, channel, target)

    print()

    return channels


# ---------------------------------------------------------------------

source_dir = check_path(source_dir)
target_dir = check_path(target_dir)

log('Converting logfiles in ' + str(source_dir))
convert_logs(source_dir, target_dir)
log('Completed\n' + ('-' * 80))
