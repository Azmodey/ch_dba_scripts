#!/bin/bash

# ClickHouse status

echo "ClickHouse processes:"
ps -afH --forest -u clickhouse | grep -v 'ps -afH' | grep -v '/usr/bin/mc'
echo

echo "ClickHouse version:"
clickhouse-server -V
echo

echo "ClickHouse network connection:"
echo "8123 - HTTP Client, 9000 - TCP/IP Native Client, 9004 - communicating using MySQL protocol, 9009 - Inter-Server Replication"
netstat -tulpn | grep clickhouse
echo

echo "ClickHouse status:"
systemctl status clickhouse-server
