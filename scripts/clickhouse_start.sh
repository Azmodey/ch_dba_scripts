#!/bin/bash

# ClickHouse start

read -p "Start ClickHouse (Y/N)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    systemctl start clickhouse-server

    echo
    echo "ClickHouse status:"
    systemctl status clickhouse-server
fi 
