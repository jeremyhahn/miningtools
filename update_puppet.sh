#!/bin/bash

rm -rf puppet/modules
/usr/bin/scp -r root@puppetmaster:/etc/puppet/modules puppet
