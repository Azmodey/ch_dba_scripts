#!/bin/bash

# Show Apache ZooKeeper log file

LOG_LINES=100							# log lines to show
LOG_DIR="/opt/zookeeper/logs"					# log direcrory
LOG_FILENAME=`ls -t $LOG_DIR/zookeeper-*.out | head -n1`	# newest log file in log directory


# show Apache ZooKeeper log
echo -e "Apache ZooKeeper log: $LOG_FILENAME"
tail -f --lines=$LOG_LINES $LOG_FILENAME
