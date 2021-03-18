#!/bin/bash

# Apache ZooKeeper stop

read -p "Stop Apache ZooKeeper (Y/N)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    systemctl stop zookeeper

    echo
    echo "Apache ZooKeeper service:"
    systemctl status zookeeper
fi 
