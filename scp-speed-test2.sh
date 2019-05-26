#!/bin/bash

server1=$1
server2=$2
script_name="scp-speed-test.sh"
scp_port=""
ssh_port=""

if test -z "$3"
then
  # default size is 10MB
  test_size="10000"
else
  test_size=$3
fi

host=${server1%%:*}
port=${server1##*:}
if [ "$host" != "$port" ]; then
    scp_port="-P $port"
    ssh_port="-p $port"
fi

scp $scp_port $script_name $host:$script_name

ssh -A -o "StrictHostKeyChecking=no" $ssh_port $host "./$script_name $server2 $test_size"

echo "Removing script file on $server1..."
ssh -o "StrictHostKeyChecking=no" $ssh_port $host "rm $script_name"
