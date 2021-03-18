#!/bin/bash

# ClickHouse stop

read -p "Stop ClickHouse (Y/N)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    systemctl stop clickhouse-server

    echo
    echo "ClickHouse status:"
    systemctl status clickhouse-server
fi 
