#!/usr/bin/env bash

sudo mkdir /mnt/$1
sudo mount -t drvfs $1: /mnt/$1
