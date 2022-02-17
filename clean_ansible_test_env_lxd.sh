#!/bin/bash

#Use this script only to claean and delete all VM
lxc delete control-server --force
lxc delete lb --force
lxc delete server1 --force
lxc delete server2 --force
lxc delete server3 --force