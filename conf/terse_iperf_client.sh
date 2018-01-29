#!/bin/sh

[ "$#" -ne 1 ] && {
  echo '{"error":"invalid args"}'
  exit 1
}

SERVER_ADDR=$1
shift

THREAD_COUNT=${THREAD_COUNT:-8}

TIME_SECONDS=${TIME_SECONDS:-10}

RESULT=$(iperf3 -c $SERVER_ADDR -P $THREAD_COUNT -t $TIME_SECONDS -J)

# need to remove literal newline from uname -a
echo $RESULT | tr -d '\n'
