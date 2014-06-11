#!/bin/bash
printf "\nFile Systems Usage\n==================\n\n"
df -hP
printf "\nMemory activity\n===============\n\n"
vmstat 2 5
printf "\nProcessor activity\n=================\n\n"
mpstat 2 5
printf "\nI/O activity\n============\n\n"
iostat 2 5
printf "\nTop processes\n=============\n\n"
top -n 1 -b | head -20
