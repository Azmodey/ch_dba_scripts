#!/bin/bash

# ClickHouse information metrics

# ------------------------------------------------
# ClickHouse client
source ./settings.txt

if [[ $CH_HOST && $CH_PORT ]]; then
  CH_CLIENT="clickhouse-client --host=$CH_HOST --port=$CH_PORT"
else
  CH_CLIENT="clickhouse-client"
fi

if [[ $CH_LOGIN && $CH_PASSWORD ]]; then
  CH_CLIENT="$CH_CLIENT --user=$CH_LOGIN --password=$CH_PASSWORD"
fi


# ------------------------------------------------

clickhouse-server -V
$CH_CLIENT --query="SELECT 'ClickHouse ' || version() || ' at ' || hostName() || '. Start time: ' || toString(now()-uptime())" --format=TSVRaw
echo

# ------------------------------------------------
echo "System metrics:"
$CH_CLIENT --query "SELECT metric, value, substring(description,1,120) as description FROM system.metrics order by metric FORMAT PrettyCompact"
echo

echo "Asynchronous metrics:"
$CH_CLIENT --query "SELECT metric, value FROM system.asynchronous_metrics ORDER BY metric FORMAT PrettyCompact"
echo

echo "System events:"
$CH_CLIENT --query "SELECT event, value, substring(description,1,119) as description FROM system.events ORDER BY event FORMAT PrettyCompact"


# ------------------------------------------------
