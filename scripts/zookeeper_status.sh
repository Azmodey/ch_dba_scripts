#!/bin/bash

# Apache ZooKeeper status


# Apache ZooKeeper hosts
ZooKeeperHosts=""								# "" - disable output
#ZooKeeperHosts="zoo_server_1 zoo_server_2 zoo_server_3"		# Servers list, hostnames. Format: "server_1" "server_2" ... 


# ---------------------------------------------------

echo "Apache ZooKeeper processes:"
ps -afH --forest -u zookeeper
echo

echo "Apache ZooKeeper network connection:"
echo "client port 2181. Cluster ports 2888 and 3888 (for leader), 3888 (for follower)"
netstat -tulpn | grep '2181\|2888\|3888'
echo

echo "Apache ZooKeeper service:"
systemctl status zookeeper
echo 

echo "Apache ZooKeeper local node status:"
/opt/zookeeper/bin/zkServer.sh status

# cluster
if [[ $ZooKeeperHosts ]]; then
  echo
  echo "Apache ZooKeeper cluster status:"
  for val in $ZooKeeperHosts; do
    ZooKeeperMode=`echo stat | nc $val 2181 | grep Mode`
    echo [$val] $ZooKeeperMode
  done
fi
