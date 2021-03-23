#!/bin/bash

# ClickHouse client

# ------------------------------------------------
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

$CH_CLIENT
#$CH_CLIENT --multiline
