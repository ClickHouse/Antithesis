#!/bin/bash

# Sanitizer options for current shell
# (but w/o verbosity for TSAN, otherwise test.reference will not match)
ENV TSAN_OPTIONS='halt_on_error=1 abort_on_error=1 history_size=7 memory_limit_mb=46080 second_deadlock_stack=1 max_allocation_size_mb=32768'
ENV UBSAN_OPTIONS='print_stacktrace=1 max_allocation_size_mb=32768'
ENV MSAN_OPTIONS='abort_on_error=1 poison_in_dtor=1 max_allocation_size_mb=32768'
ENV LSAN_OPTIONS='max_allocation_size_mb=32768'
ENV ASAN_OPTIONS='halt_on_error=1 abort_on_error=1'

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