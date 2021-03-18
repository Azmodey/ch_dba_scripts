#!/bin/bash

# Refresh clickhouse_activity.sh script

i=0
while [ i==0 ]
do
  ./clickhouse_activity.sh > clickhouse_activity.txt
  clear
  cat ./clickhouse_activity.txt
  sleep 5
done 
