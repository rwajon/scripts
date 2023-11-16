#!/bin/bash

command=${@}

eval $(echo $(cat .env | grep -v "#" | awk 'ORS=" "') $command)
