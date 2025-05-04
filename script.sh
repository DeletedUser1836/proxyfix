#!/bin/bash

# If we want to change params in proxychains config file
if [ $1 -eq "-c" ]
then
    sudo nano /etc/proxychains4.conf
fi

if [ $1 -eq "-CPS" ]
then
   sudo nano /etc/proxychains4.conf && 