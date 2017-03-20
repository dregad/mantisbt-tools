#!/usr/bin/env php
<?php
/**
 * This will restore the MantisBT database to its previous state after a
 * user has spammed the tracker by mass-adding bug notes.
 *
 * Instructions:
 * 1. Specify user id of the spammer in variable below and save the script
 *    in MantisBT folder
 * 2. Run the script
 */

$t_user_id = 37486;

# -----------------------------------------------------------------------------

include( 'core.php' );

ob_end_flush();
ob_end_flush();

user_ensure_exists( $t_user_id );

echo "Ready to restore bugtracker after spamming by user id $t_user_id ("
	. user_get_name( $t_user_id )
	. ")\n";
readline( "Press (ctrl-c to abort)\n" );


# Identify all modified bugs (from bugnotes added by spammer)
$t_query = '
	SELECT DISTINCT bug_id
	FROM {bugnote}
	WHERE reporter_id=' . db_param();
$t_updated_bugs = db_query( $t_query, array( $t_user_id ) );


# Delete history records generated by the spammer
echo "Deleting history records...\n";
$t_query = '
	DELETE FROM {bug_history}
	WHERE type=' . BUGNOTE_ADDED . ' AND user_id=' . db_param();
db_query( $t_query, array( $t_user_id ) );


# Reset bugs' last updated date
echo "Restoring bugs' last updated date...\n";
while( $t_bug = db_fetch_array( $t_updated_bugs ) ) {
	$t_bug_id = $t_bug['bug_id'];

	# Get timestamp of most recent remaining history entry
	$t_query = '
		SELECT date_modified
		FROM {bug_history}
		WHERE bug_id=' . db_param() . '
		ORDER BY id DESC
		LIMIT 1';
	$t_last_updated = db_result( db_query( $t_query, array( $t_bug_id ) ) );
	if( !$t_last_updated ) {
		# No history record found, use bug's submitted date
		$t_last_updated = bug_get_field( $t_bug_id, 'date_submitted' );
	}

	# Set last_updated date
	$t_query = '
		UPDATE {bug}
		SET last_updated=' . db_param() . '
		WHERE id=' . db_param();
	db_query( $t_query, array( $t_last_updated, $t_bug_id ) );
}


# Delete bugnotes
echo "Deleting bugnotes...\n";
$t_query = '
	DELETE t.*
	FROM {bugnote_text} t
	JOIN {bugnote} n ON n.bugnote_text_id=t.id
	WHERE n.reporter_id=' . db_param();
db_query( $t_query, array( $t_user_id ) );

$t_query = '
	DELETE FROM {bugnote}
	WHERE reporter_id=' . db_param();
db_query( $t_query, array( $t_user_id ) );


echo "Done\n";