#!/bin/bash
lxc delete control-server --force
lxc delete lb --force
lxc delete server1 --force
lxc delete server2 --force
lxc delete server3 --force