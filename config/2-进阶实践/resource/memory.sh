#!/bin/bash
#################################################################
#### @Author: alex
#### @Date:   2020-03-05 12:45:34
#### usage:
#### any questions,please mail to alex
#################################################################
s="aaaaaaaaaaaaaaaaaa"
i=1
while true;
do
    i+=1
    s="$s$s"
    echo $i
    sleep 0.5
done
