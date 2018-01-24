#!/bin/sh

echo "terse return"

exit 0

[ "$#" -ne 1 ] && {
  echo too many arguments
  exit 1
}

SERVER_ADDR=$1
shift

iperf -P 8 -c $SERVER_ADDR