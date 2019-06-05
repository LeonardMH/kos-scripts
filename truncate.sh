#!/bin/sh
cat $1 | tr -d '\n' > $1
