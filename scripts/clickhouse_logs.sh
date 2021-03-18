#!/bin/bash

# ClickHouse log file
LOG_LINES=100								# Number of ClickHouse log lines to display. 0 - disable output
LOG_FILENAME="/var/log/clickhouse-server/clickhouse-server.log"		# ClickHouse log file name


# show ClickHouse log
echo -e "ClickHouse log: $LOG_FILENAME"
tail -f --lines=$LOG_LINES $LOG_FILENAME 
