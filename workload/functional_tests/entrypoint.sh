#!/bin/bash

echo "waiting for clickhouse server to start"

# Wait for the server to start, but not for too long.
ELAPSED=0
started=$(mktemp)
echo "False" > $started
until clickhouse-client --query "SELECT 1" && echo "True" > $started || [ $ELAPSED -eq 100 ]
do
  sleep 1
  (( ELAPSED++ ))
done

if [[ $(cat $started) == "True" ]]
then
    echo "Clickhouse server started!"
else
    echo "Clickhouse server failed to start after $ELAPSED seconds"
    exit 1
fi

sleep infinity