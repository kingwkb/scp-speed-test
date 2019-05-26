#!/bin/bash
# scp-speed-test.sh
#
# Usage:
#   ./scp-speed-test.sh user@hostname [test file size in kBs]
#
#############################################################

ssh_server=$1
test_file=".scp-test-file"
scp_port=""
ssh_port=""

# Optional: user specified test file size in kBs
if test -z "$2"
then
  # default size is 10MB
  test_size="10000"
else
  test_size=$2
fi

host=${ssh_server%%:*}
port=${ssh_server##*:}
if [ "$host" != "$port" ]; then
    scp_port="-P $port"
    ssh_port="-p $port"
fi

# generate a file of all zeros
echo "Generating $test_size kB test file..."
dd if=/dev/zero of=$test_file bs=$(echo "$test_size*1024" | bc) \
  count=1 &> /dev/null
# upload test
echo "Testing upload to $ssh_server..."
up_speed=$(scp -o "StrictHostKeyChecking=no" $scp_port -v $test_file $host:$test_file 2>&1 | \
  grep "Bytes per second" | \
  sed "s/^[^0-9]*\([0-9.]*\)[^0-9]*\([0-9.]*\).*$/\1/g")
up_speed=$(echo "($up_speed*0.0009765625*100.0+0.5)/1*0.01" | bc)

# download test
echo "Testing download from $ssh_server..."
down_speed=$(scp -o "StrictHostKeyChecking=no" $scp_port -v $host:$test_file $test_file 2>&1 | \
  grep "Bytes per second" | \
  sed "s/^[^0-9]*\([0-9.]*\)[^0-9]*\([0-9.]*\).*$/\2/g")
down_speed=$(echo "($down_speed*0.0009765625*100.0+0.5)/1*0.01" | bc)

# clean up
echo "Removing test file on $ssh_server..."
ssh -o "StrictHostKeyChecking=no" $ssh_port $host "rm $test_file"
echo "Removing test file locally..."
rm $test_file


# print result
echo ""
echo "Upload speed:   $up_speed kB/s"
echo "Download speed: $down_speed kB/s"
