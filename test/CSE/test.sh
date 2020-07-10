#!/bin/bash

echo creating folder $1
mkdir -p -v $1

echo creating file $2
touch $2

sleep $3
echo done
