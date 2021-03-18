#!/bin/bash

# Apache ZooKeeper start

read -p "Start Apache ZooKeeper (Y/N)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    systemctl start zookeeper

    echo
    echo "Apache ZooKeeper service:"
    systemctl status zookeeper
fi 
