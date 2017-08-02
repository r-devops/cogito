#!/bin/bash

USER=$1

id $USER &>/dev/null
case $? in
  0) echo User Exists ;;
  *) echo User not Exists ;;
esac
