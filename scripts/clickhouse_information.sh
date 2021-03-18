#!/bin/bash

# ClickHouse information

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

echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

clickhouse-server -V
clickhouse-client --query="SELECT 'ClickHouse ' || version() || ' at ' || hostName() || '. Start time: ' || toString(now()-uptime())" --format=TSVRaw
echo

echo "ClickHouse disks:"
clickhouse-client --query "SELECT name, path, formatReadableSize(sum(free_space)) as free_space, formatReadableSize(sum(total_space)) as total_space, 
       formatReadableSize(sum(keep_free_space)) as keep_free_space, type
FROM system.disks
GROUP BY name, path, type FORMAT PrettyCompact"
echo

echo "Storage policies and volumes:"
clickhouse-client --query "select * from system.storage_policies FORMAT PrettyCompact"
echo

echo "Databases:"
clickhouse-client --query "SELECT d.name, formatReadableSize(sum(p.bytes_on_disk)) as size, d.engine, d.data_path, d.metadata_path, d.uuid 
FROM system.databases d LEFT JOIN system.parts p ON d.name = p.database
GROUP BY d.name, d.engine, d.data_path, d.metadata_path, d.uuid 
ORDER BY sum(p.bytes_on_disk) DESC FORMAT PrettyCompact"
echo

echo "Clusters:"
clickhouse-client --query "select cluster, shard_num, shard_weight, replica_num, host_name, host_address, port, is_local, errors_count, estimated_recovery_time as recovery_time from system.clusters FORMAT PrettyCompact"
echo

echo "Macros settings for local cluster:"
clickhouse-client --query "SELECT * FROM system.macros FORMAT PrettyCompact"
echo

echo "External dictionaries:"
clickhouse-client --query "
SELECT database, name, status, origin, type, key, formatReadableSize(bytes_allocated) as size, query_count, hit_rate, element_count, load_factor, source, last_exception 
FROM system.dictionaries FORMAT  PrettyCompact"
echo

echo "Zookeeper:"
clickhouse-client --query="SELECT name, value, czxid, mzxid, ctime, mtime, version as ver, cversion as cver, aversion as aver, ephemeralOwner as ephOwner, dataLength, numChildren, pzxid, path FROM system.zookeeper WHERE path='/'" --format=PrettyCompactMonoBlock
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "Settings that have been changed:"
clickhouse-client --query="SELECT name, value, changed, substring(description,1,80) as description, min, max, readonly, type FROM system.settings WHERE changed FORMAT PrettyCompact"
echo

echo "Settings profiles. Properties of configured setting profiles:"
clickhouse-client --query="SELECT * FROM system.settings_profiles FORMAT PrettyCompact"
echo

echo "Settings profile elements. Content of the settings profile:"
clickhouse-client --query="SELECT * FROM system.settings_profile_elements FORMAT PrettyCompact"
echo

echo "Error codes with the number of times they have been triggered:"
clickhouse-client --query="SELECT * FROM system.errors FORMAT PrettyCompact"
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "Users:"
clickhouse-client --query "SELECT name, storage, auth_type, auth_params, host_ip, host_names, default_roles_all, default_roles_list, default_roles_except FROM system.users FORMAT PrettyCompact"
echo

echo "Grants. Privileges granted to ClickHouse user accounts:"
clickhouse-client --query "SELECT * FROM system.grants FORMAT PrettyCompact"
echo

echo "Roles:"
clickhouse-client --query "SELECT * FROM system.roles FORMAT PrettyCompact"
echo

echo "Role grants:"
clickhouse-client --query "SELECT * FROM system.role_grants FORMAT PrettyCompact"
echo

echo "Settings profiles:"
clickhouse-client --query "SELECT * FROM system.settings_profiles FORMAT PrettyCompact"
echo

echo "Row policies for the specified table:"
clickhouse-client --query "SELECT * FROM system.row_policies FORMAT PrettyCompact"
echo

echo "Quotas:"
clickhouse-client --query "SELECT * FROM system.quotas FORMAT PrettyCompact"
echo

echo "Quota consumption for all users:"
clickhouse-client --query "SELECT quota_name, quota_key, is_current, queries, max_queries, errors, result_rows, result_bytes, read_rows, read_bytes, execution_time FROM system.quotas_usage FORMAT PrettyCompact"
echo

echo "Quota limits. Information about maximums for all intervals of all quotas:"
clickhouse-client --query "
SELECT quota_name, duration, is_randomized_interval as rand_interval, max_queries as queries, max_query_selects as query_selects, 
       max_query_inserts as query_inserts, max_errors, max_result_rows as result_rows, max_result_bytes as result_bytes, 
       max_read_rows as read_rows, max_read_bytes as read_bytes, max_execution_time as exec_time 
FROM system.quota_limits FORMAT PrettyCompact"
echo

echo "SHOW ACCESS - all users, roles, profiles, etc. and all their grants:"
clickhouse-client --query "SHOW ACCESS FORMAT PrettyCompact"
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "Tables compress ratio:"
clickhouse-client --query "
SELECT database, table, count(*) AS parts,
    uniq(partition) AS partitions,
    sum(marks) AS marks,
    sum(rows) AS rows,
    formatReadableSize(sum(data_compressed_bytes)) AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes)) AS uncompressed,
    round((sum(data_compressed_bytes) / sum(data_uncompressed_bytes)) * 100., 2) AS percentage
FROM system.parts WHERE active='1'
GROUP BY database, table 
ORDER BY database, rows DESC
LIMIT 50 FORMAT PrettyCompact"
echo

echo "Top tables by size:"
clickhouse-client --query "
SELECT database, name, engine, is_temporary, metadata_modification_time, storage_policy, total_rows, round(sum(total_bytes) / 1024/1024/1024, 2) as size_gb
FROM system.tables 
WHERE database != 'system' 
GROUP BY database, name, engine, is_temporary, metadata_modification_time, storage_policy, total_rows, total_bytes
ORDER BY database, total_bytes DESC 
LIMIT 10 FORMAT PrettyCompact"
echo

echo "Top tables MergeTree families by size:"
clickhouse-client --query "
SELECT database, table, engine, disk_name, sum(rows) as rows, round(sum(bytes) / 1024/1024/1024, 2) as size_gb, countIf(active) data_parts_active, countIf(not active) data_parts_not_active
FROM system.parts
-- WHERE active
GROUP BY database, table, engine, disk_name
ORDER BY size_gb DESC 
LIMIT 10 FORMAT PrettyCompact"
echo

echo "Tables in memory (Memory engine):"
clickhouse-client --query "
SELECT database, name, formatReadableSize(total_bytes)
FROM system.tables
WHERE engine = 'Memory' 
ORDER BY total_bytes DESC
LIMIT 10 FORMAT PrettyCompact"
echo

echo "Detached parts of MergeTree tables:"
clickhouse-client --query "SELECT * FROM system.detached_parts ORDER BY database, table FORMAT PrettyCompact"
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "Replicated tables located on the local server:"
clickhouse-client --query "
SELECT database, table, engine, is_leader as leader, is_readonly as readonly, parts_to_check, 
       queue_size, inserts_in_queue as queue_insert, merges_in_queue as queue_merge,	-- очередь
       log_max_index, log_pointer, total_replicas as tot_repl, active_replicas as act_repl -- ZooKeeper
FROM system.replicas FORMAT PrettyCompact"
echo

echo "Replication queue. Tasks from replication queues stored in ZooKeeper for tables in the ReplicatedMergeTree family:"
clickhouse-client --query "
SELECT database, table, replica_name, position, node_name, type, create_time, num_tries, last_attempt_time, num_postponed, last_postpone_time
FROM system.replication_queue FORMAT PrettyCompact"
echo

echo "Replicated fetches. Currently running background fetches:"
clickhouse-client --query "
SELECT database, table, elapsed, progress, result_part_name, partition_id, source_replica_hostname, source_replica_port, interserver_scheme, to_detached, thread_id 
FROM system.replicated_fetches ORDER BY database, table FORMAT PrettyCompact"
echo

echo "Distribution queue. Local files that are in the queue to be sent to the shards. Contain new parts that are created by inserting new data into the Distributed table:"
clickhouse-client --query "SELECT database, table, is_blocked, error_count, data_files, data_compressed_bytes, last_exception FROM system.distribution_queue ORDER BY database, table FORMAT PrettyCompact"
echo

echo "Merges and part mutations currently in process for tables in the MergeTree family:"
clickhouse-client --query "SELECT database, table, elapsed, progress, num_parts, rows_read, rows_written, memory_usage, merge_type, merge_algorithm FROM system.merges FORMAT PrettyCompact"
echo

echo "Mutations of MergeTree tables and their progress (ALTER command):"
echo "- kill: KILL MUTATION WHERE database = 'default' AND table = 'table'"
clickhouse-client --query "SELECT database, table, mutation_id, command, create_time, parts_to_do, is_done, latest_failed_part, latest_fail_time, latest_fail_reason FROM system.mutations FORMAT PrettyCompact"
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "Longest running queries:"
clickhouse-client --query "
SELECT user, 
    --client_hostname AS host, 
    --client_name AS client, 
    --formatDateTime(query_start_time, '%T') AS started, 
    query_duration_ms / 1000 AS dur_sec, 
    round(memory_usage / 1048576) AS mem_mb,
    result_rows, 
    formatReadableSize(result_bytes) AS result_size, 
    read_rows, 
    formatReadableSize(read_bytes) AS read_size,
    written_rows as write_rows, 
    formatReadableSize(written_bytes) AS write_size,
    query_id,
    substring(query,1,30) as query
  FROM system.query_log
 WHERE type = 2
 ORDER BY query_duration_ms DESC
 LIMIT 10 FORMAT PrettyCompact"
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "System activity:"

MAX_USER_TIME=`clickhouse-client --query "
SELECT user_time FROM (
 SELECT toStartOfDay(event_time) AS time, sum(ProfileEvent_UserTimeMicroseconds) AS user_time
 FROM system.metric_log WHERE event_date >= date_sub(DAY, 14, today()) GROUP BY time ORDER BY user_time DESC LIMIT 1
)"`

MAX_INSERTED_ROWS=`clickhouse-client --query "
SELECT inserted_rows FROM (
 SELECT toStartOfDay(event_time) AS time, sum(ProfileEvent_InsertedRows) as inserted_rows
 FROM system.metric_log WHERE event_date >= date_sub(DAY, 14, today()) GROUP BY time ORDER BY inserted_rows DESC LIMIT 1
)"`

MAX_SELECTED_ROWS=`clickhouse-client --query "
SELECT selected_rows FROM (
 SELECT toStartOfDay(event_time) AS time, sum(ProfileEvent_SelectedRows) as selected_rows
 FROM system.metric_log WHERE event_date >= date_sub(DAY, 14, today()) GROUP BY time ORDER BY selected_rows DESC LIMIT 1
)"`

MAX_MERGED_ROWS=`clickhouse-client --query "
SELECT merged_rows FROM (
 SELECT toStartOfDay(event_time) AS time, sum(ProfileEvent_MergedRows) as merged_rows
 FROM system.metric_log WHERE event_date >= date_sub(DAY, 14, today()) GROUP BY time ORDER BY merged_rows DESC LIMIT 1
)"`

# 14 days
clickhouse-client --query "
SELECT toStartOfDay(event_time) AS time,
       sum(ProfileEvent_UserTimeMicroseconds) AS user_time,
       bar(user_time, 0, $MAX_USER_TIME, 15) AS user_time_bar,
       sum(ProfileEvent_InsertedRows) as inserted_rows,
       bar(inserted_rows, 0, $MAX_INSERTED_ROWS, 15) AS insert_rows_bar,
       formatReadableSize(sum(ProfileEvent_InsertedBytes)) as inserted,
       sum(ProfileEvent_SelectedRows) as selected_rows,
       bar(selected_rows, 0, $MAX_SELECTED_ROWS, 15) AS selected_rows_bar,
       formatReadableSize(sum(ProfileEvent_SelectedBytes)) as selected,
       sum(ProfileEvent_MergedRows) as merged_rows,
       bar(merged_rows, 0, $MAX_MERGED_ROWS, 15) AS merged_rows_bar
  FROM system.metric_log
 WHERE event_date >= date_sub(DAY, 14, today())
 GROUP BY time ORDER BY time FORMAT PrettyCompact"

# today by hours
clickhouse-client --query "
SELECT toStartOfHour(event_time) AS time,
       sum(ProfileEvent_UserTimeMicroseconds) AS user_time,
       bar(user_time, 0, $MAX_USER_TIME, 15) AS user_time_bar,
       sum(ProfileEvent_InsertedRows) as inserted_rows,
       bar(inserted_rows, 0, $MAX_INSERTED_ROWS, 15) AS insert_rows_bar,
       formatReadableSize(sum(ProfileEvent_InsertedBytes)) as inserted,
       sum(ProfileEvent_SelectedRows) as selected_rows,
       bar(selected_rows, 0, $MAX_SELECTED_ROWS, 15) AS selected_rows_bar,
       formatReadableSize(sum(ProfileEvent_SelectedBytes)) as selected,
       sum(ProfileEvent_MergedRows) as merged_rows,
       bar(merged_rows, 0, $MAX_MERGED_ROWS, 15) AS merged_rows_bar
  FROM system.metric_log
 WHERE event_date >= date_sub(HOUR, 48, today())
 GROUP BY time ORDER BY time FORMAT PrettyCompact"

# today by minute (last 60 minutes)
clickhouse-client --query "
SELECT toStartOfMinute(event_time) AS time,
       sum(ProfileEvent_UserTimeMicroseconds) AS user_time,
       bar(user_time, 0, $MAX_USER_TIME, 15) AS user_time_bar,
       sum(ProfileEvent_InsertedRows) as inserted_rows,
       bar(inserted_rows, 0, $MAX_INSERTED_ROWS, 15) AS insert_rows_bar,
       formatReadableSize(sum(ProfileEvent_InsertedBytes)) as inserted,
       sum(ProfileEvent_SelectedRows) as selected_rows,
       bar(selected_rows, 0, $MAX_SELECTED_ROWS, 15) AS selected_rows_bar,
       formatReadableSize(sum(ProfileEvent_SelectedBytes)) as selected,
       sum(ProfileEvent_MergedRows) as merged_rows,
       bar(merged_rows, 0, $MAX_MERGED_ROWS, 15) AS merged_rows_bar
  FROM system.metric_log
 WHERE event_time >= timestamp_sub(minute, 60, now())
 GROUP BY time ORDER BY time FORMAT PrettyCompact"
echo



echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

echo "Queries that is being processed. Ordered by elapsed time:"
echo "- full SQL text by query_id: SELECT distinct query FROM system.query_log WHERE query_id='' FORMAT TabSeparatedRaw"
echo "- kill: KILL QUERY WHERE query_id='2-857d-4a57-9ee0-327da5d60a90'"
echo "- kill: KILL QUERY WHERE user='username' SYNC"
clickhouse-client --query "SELECT elapsed as time_seconds, formatReadableSize(memory_usage) as memory, formatReadableSize(read_bytes) as read, read_rows, total_rows_approx as total_rows, user, address as client, query_id, substring(query,1,48) as query
FROM system.processes
ORDER BY elapsed desc FORMAT PrettyCompact"
echo

echo "Queries that is being processed. Ordered by memory usage:"
clickhouse-client --query "SELECT elapsed as time_seconds, formatReadableSize(memory_usage) as memory, formatReadableSize(read_bytes) as read, read_rows, total_rows_approx as total_rows, user, address as client, query_id, substring(query,1,48) as query
FROM system.processes
ORDER BY memory_usage desc FORMAT PrettyCompact"
echo

echo -e "${CYANLIGHT}---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

