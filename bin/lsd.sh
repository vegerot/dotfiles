#!/usr/bin/env bash

du -sh *|sort -h -r|head -n ${1-10}
