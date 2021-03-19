#!/bin/bash

# ClickHouse activity


# ClickHouse log file
LOG_LINES=0								# Number of ClickHouse log lines to display. 0 - disable output
LOG_FILENAME="/var/log/clickhouse-server/clickhouse-server.log"		# ClickHouse log file name

# Apache ZooKeeper hosts
ZooKeeperHosts=""							# "" - disable output
#ZooKeeperHosts="zoo_server_1 zoo_server_2 zoo_server_3"		# Servers list, hostnames. Format: "server_1" "server_2" ... 


# ------------------------------------------------
# Colors
GREYDARK='\033[1;30m'
RED='\033[0;31m'
REDLIGHT='\033[1;31m'
GREEN='\033[0;32m'
GREENLIGHT='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BLUELIGHT='\033[1;34m'
PURPLE='\033[0;35m'
PURPLELIGHT='\033[1;35m'
CYAN='\033[0;36m'
CYANLIGHT='\033[1;36m'
WHITE='\033[1;37m'
#
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'
 

# ------------------------------------------------

# System
PLATFORM=`awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"'`	# Red Hat Enterprise Linux Server / CentOS Linux / Debian GNU/Linux / Ubuntu


# Apache ZooKeeper
ZOO_STATUS="| "
for val in $ZooKeeperHosts; do
  ZooKeeperMode=`echo stat | nc $val 2181 | grep Mode`

  if [[ $ZooKeeperMode = *Mode* ]]; then
    ZOO_STATUS="$ZOO_STATUS[$val] ${GREENLIGHT}$ZooKeeperMode${NC} | "
  else
    ZOO_STATUS="$ZOO_STATUS[$val] ${REDLIGHT}Fail${NC} | "
  fi

done


# ClickHouse clusters
CLICKHOUSE_CLUSTERS=`clickhouse-client --query "SELECT distinct host_name FROM system.clusters WHERE host_name not in ('127.0.0.1', '127.0.0.2', 'localhost')"`

CLICKHOUSE_CLUSTER_STATUS="| "
for cluster in $CLICKHOUSE_CLUSTERS ; do 
  CLUSTER_VER=`clickhouse-client --host $cluster --query "SELECT version()" 2> /dev/null`
  #echo "[$cluster] ver [$CLUSTER_VER]"

  re='^[0-9]+([.][0-9]+)+([.][0-9]+)+([.][0-9]+)$'
  if ! [[ $CLUSTER_VER =~ $re ]] ; then
     # Not a number
     CLICKHOUSE_CLUSTER_STATUS="$CLICKHOUSE_CLUSTER_STATUS[$cluster] ${REDLIGHT}Fail${NC} | "
  else
     # Number
     CLICKHOUSE_CLUSTER_STATUS="$CLICKHOUSE_CLUSTER_STATUS[$cluster] ${GREENLIGHT}Active${NC} | "
  fi
  
done


# Title (1st line)
DATE=$(date '+%d.%m.%Y %H:%M:%S')
HOST=`hostname --short`
HOSTIP=`hostname -I | xargs`
UPTIME=`uptime`
UPTIME=${UPTIME#*load average: }

if [[ $PLATFORM == "Red Hat Enterprise Linux Server" || $PLATFORM == "CentOS Linux" ]]; then
  IOSTAT_AWAIT=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 11`
  IOSTAT_UTIL=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 15`
fi
if [[ $PLATFORM == "Debian GNU/Linux" ]]; then
  IOSTAT_R_AWAIT=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 11 | sed 's/,/./g'`
  IOSTAT_W_AWAIT=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 12 | sed 's/,/./g'`
  IOSTAT_UTIL=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 17 | sed 's/,/./g'`

  IOSTAT_AWAIT=`awk "BEGIN {print ($IOSTAT_R_AWAIT+$IOSTAT_W_AWAIT)/2}"`
fi
if [[ $PLATFORM == "Ubuntu" ]]; then
  IOSTAT_R_AWAIT=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 7 | sed 's/,/./g'`
  IOSTAT_W_AWAIT=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 13 | sed 's/,/./g'`
  IOSTAT_UTIL=`iostat -d -x -g ALL | grep ALL | tr -s " " | cut -d " " -f 22 | sed 's/,/./g'`

  IOSTAT_AWAIT=`awk "BEGIN {print ($IOSTAT_R_AWAIT+$IOSTAT_W_AWAIT)/2}"`
fi 

CLICKHOUSE_VER=`clickhouse-server -V`
CLICKHOUSE_VER=${CLICKHOUSE_VER#"ClickHouse server version "}
CLICKHOUSE_VER=`echo $CLICKHOUSE_VER | rev | cut -c 2- | rev`

STATUS="${GREENLIGHT}[$HOST ($HOSTIP) / ClickHouse $CLICKHOUSE_VER]${YELLOW}"


# ------------------------------------------------

# Title (1st line)
echo -e "${YELLOW}[$DATE] $STATUS [CPU load (1/5/15 min): $UPTIME] [Disk load: util $IOSTAT_UTIL %, await $IOSTAT_AWAIT ms] ${NC}"

# Title (2nd line)
if [[ $ZooKeeperHosts ]]; then
  echo -e "${GREENLIGHT}Apache ZooKeeper cluster:${NC} $ZOO_STATUS"
fi

echo


# ------------------------------------------------

echo -e "${GREENLIGHT}ClickHouse disks:${NC}"
clickhouse-client --query "SELECT name, path, formatReadableSize(sum(free_space)) as free_space, formatReadableSize(sum(total_space)) as total_space, 
       formatReadableSize(sum(keep_free_space)) as keep_free_space, type
FROM system.disks
GROUP BY name, path, type FORMAT PrettyCompact"
echo

echo -e "${GREENLIGHT}Databases:${NC}"
clickhouse-client --query "SELECT d.name, formatReadableSize(sum(p.bytes_on_disk)) as size, d.engine, d.data_path, d.metadata_path, d.uuid 
FROM system.databases d LEFT JOIN system.parts p ON d.name = p.database
GROUP BY d.name, d.engine, d.data_path, d.metadata_path, d.uuid 
ORDER BY sum(p.bytes_on_disk) DESC FORMAT PrettyCompact"
echo

echo -e "${GREENLIGHT}Clusters:${NC}"
clickhouse-client --query "
  SELECT cluster, shard_num, shard_weight, replica_num, host_name, host_address, port, is_local, errors_count, estimated_recovery_time
  FROM system.clusters 
  WHERE host_name not in ('127.0.0.1', '127.0.0.2', 'localhost')
  FORMAT PrettyCompact"
echo -e "${GREENLIGHT}Cluster status:${NC} $CLICKHOUSE_CLUSTER_STATUS"
echo


replicated_tables=`clickhouse-client --query "SELECT table FROM system.replicas"`
if [[ ${#replicated_tables} >0 ]]; then 
  echo -e "${GREENLIGHT}Replicated tables located on the local server:${NC}"
  clickhouse-client --query "
  SELECT database, table, engine, is_leader as leader, is_readonly as readonly, parts_to_check, 
         queue_size, inserts_in_queue as queue_insert, merges_in_queue as queue_merge,	-- очередь
         log_max_index, log_pointer, total_replicas as tot_repl, active_replicas as act_repl -- ZooKeeper
  FROM system.replicas FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


replication_problems=`clickhouse-client --query "SELECT table FROM system.replicas 
 WHERE is_readonly OR is_session_expired OR future_parts > 20 OR parts_to_check > 10 OR queue_size > 20 
    OR inserts_in_queue > 10 OR log_max_index - log_pointer > 10 OR total_replicas < 2 
    OR active_replicas < total_replicas"`
if [[ ${#replication_problems} >0 ]]; then 
  echo -e "${REDLIGHT}Replication problems:${NC}"
  clickhouse-client --query "
  SELECT database, table, is_leader, total_replicas, active_replicas 
    FROM system.replicas 
   WHERE is_readonly 
      OR is_session_expired 
      OR future_parts > 20 
      OR parts_to_check > 10 
      OR queue_size > 20 
      OR inserts_in_queue > 10 
      OR log_max_index - log_pointer > 10 
      OR total_replicas < 2 
      OR active_replicas < total_replicas FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


replication_queue=`clickhouse-client --query "SELECT table FROM system.replication_queue"`
if [[ ${#replication_queue} >0 ]]; then 
  echo -e "${GREENLIGHT}Replication queue.${NC} Tasks from replication queues stored in ZooKeeper for tables in the ReplicatedMergeTree family:"
  clickhouse-client --query "
  SELECT database, table, replica_name, position, node_name, type, create_time, num_tries, last_attempt_time, num_postponed, last_postpone_time
  FROM system.replication_queue FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


replicated_fetches=`clickhouse-client --query "SELECT table FROM system.replicated_fetches"`
if [[ ${#replicated_fetches} >0 ]]; then 
  echo -e "${GREENLIGHT}Replicated fetches.${NC} Currently running background fetches:"
  clickhouse-client --query "
  SELECT database, table, elapsed, progress, result_part_name, partition_id, source_replica_hostname, source_replica_port, interserver_scheme, to_detached, thread_id 
  FROM system.replicated_fetches ORDER BY database, table FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


distribution_queue=`clickhouse-client --query "SELECT table FROM system.distribution_queue"`
if [[ ${#distribution_queue} >0 ]]; then 
  echo -e "${GREENLIGHT}Distribution queue.${NC} Local files that are in the queue to be sent to the shards. Contain new parts that are created by inserting new data into the Distributed table:"
  clickhouse-client --query "SELECT database, table, is_blocked, error_count, data_files, data_compressed_bytes, last_exception FROM system.distribution_queue ORDER BY database, table FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


merges=`clickhouse-client --query "SELECT table FROM system.merges"`
if [[ ${#merges} >0 ]]; then 
  echo -e "${YELLOW}Merges and part mutations currently in process for tables in the MergeTree family:${NC}"
  clickhouse-client --query "SELECT database, table, elapsed, progress, num_parts, rows_read, rows_written, memory_usage, merge_type, merge_algorithm FROM system.merges FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


table_mutations=`clickhouse-client --query "SELECT table FROM system.mutations"`
if [[ ${#table_mutations} >0 ]]; then 
  echo -e "${YELLOW}Mutations of MergeTree tables and their progress (ALTER command):${NC}"
  clickhouse-client --query "SELECT database, table, mutation_id, command, create_time, parts_to_do, is_done, latest_failed_part, latest_fail_time, latest_fail_reason FROM system.mutations FORMAT PrettyCompact"
  echo
  LOG_LINES=$((LOG_LINES-5)) 
fi


echo -e "${GREENLIGHT}Queries that is being processed.${NC} Full SQL text by query_id: SELECT distinct query FROM system.query_log WHERE query_id='' FORMAT TabSeparatedRaw"
clickhouse-client --query "SELECT user, address as client, elapsed as time_seconds, formatReadableSize(memory_usage) as memory, formatReadableSize(read_bytes) as read, read_rows, total_rows_approx as total_rows, query_id, substring(query,1,40) as query
FROM system.processes
ORDER BY elapsed desc FORMAT PrettyCompact"
echo


# show ClickHouse log
if [[ $LOG_LINES -gt 0 ]]; then
  echo -e "${GREENLIGHT}ClickHouse log:${NC} $LOG_FILENAME"
  tail --lines=$LOG_LINES $LOG_FILENAME 
fi
