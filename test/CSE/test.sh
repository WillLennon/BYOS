#!/bin/bash

echo creating folder $1
mkdir -p -v $1

echo creating file $2
touch $2

echo sleeping $3
sleep $3

echo done
