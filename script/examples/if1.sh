#!/bin/bash

USER=$1
id $USER &>/dev/null
if [ $? -eq 0 ]; then 
	echo User exists
else
	echo User does not exists
	exit 1
fi
