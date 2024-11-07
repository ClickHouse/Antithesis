#!/bin/bash

# fail on errors, verbose and export all env variables
set -e -x -a

# shellcheck disable=SC1091d
source /scripts/setup_export_logs.sh

# shellcheck source=../stateless/stress_tests.lib
source /scripts/stress_tests.lib

# fail on errors, verbose and export all env variables
set -e -x -a

USE_DATABASE_REPLICATED=${USE_DATABASE_REPLICATED:=0}
USE_SHARED_CATALOG=${USE_SHARED_CATALOG:=0}

# Choose random timezone for this test run.
#
# NOTE: that clickhouse-test will randomize session_timezone by itself as well
# (it will choose between default server timezone and something specific).
#TZ="$(rg -v '#' /usr/share/zoneinfo/zone.tab  | awk '{print $3}' | shuf | head -n1)"
#echo "Chosen random timezone $TZ"
#ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

ln -sf /tests/clickhouse-test /usr/bin/clickhouse-test

export CLICKHOUSE_GRPC_CLIENT="/utils/grpc-client/clickhouse-grpc-client.py"

# shellcheck disable=SC1091
source /tests/docker_scripts/attach_gdb.lib

# shellcheck disable=SC1091
source /tests/docker_scripts/utils.lib

# install test configs - the config files are already on the servers
#/tests/config/install.sh

# /tests/docker_scripts/setup_minio.sh stateless

# /tests/docker_scripts/setup_hdfs_minicluster.sh

#config_logs_export_cluster /etc/clickhouse-server/config.d/system_logs_export.yaml

# export IS_FLAKY_CHECK=0

# Export NUM_TRIES so python scripts will see its value as env variable
export NUM_TRIES=1

# For flaky check we also enable thread fuzzer
# if [ "$NUM_TRIES" -gt "1" ]; then
#     export IS_FLAKY_CHECK=1

#     export THREAD_FUZZER_CPU_TIME_PERIOD_US=1000
#     export THREAD_FUZZER_SLEEP_PROBABILITY=0.1
#     export THREAD_FUZZER_SLEEP_TIME_US_MAX=100000

#     export THREAD_FUZZER_pthread_mutex_lock_BEFORE_MIGRATE_PROBABILITY=1
#     export THREAD_FUZZER_pthread_mutex_lock_AFTER_MIGRATE_PROBABILITY=1
#     export THREAD_FUZZER_pthread_mutex_unlock_BEFORE_MIGRATE_PROBABILITY=1
#     export THREAD_FUZZER_pthread_mutex_unlock_AFTER_MIGRATE_PROBABILITY=1

#     export THREAD_FUZZER_pthread_mutex_lock_BEFORE_SLEEP_PROBABILITY=0.001
#     export THREAD_FUZZER_pthread_mutex_lock_AFTER_SLEEP_PROBABILITY=0.001
#     export THREAD_FUZZER_pthread_mutex_unlock_BEFORE_SLEEP_PROBABILITY=0.001
#     export THREAD_FUZZER_pthread_mutex_unlock_AFTER_SLEEP_PROBABILITY=0.001
#     export THREAD_FUZZER_pthread_mutex_lock_BEFORE_SLEEP_TIME_US_MAX=10000
#     export THREAD_FUZZER_pthread_mutex_lock_AFTER_SLEEP_TIME_US_MAX=10000
#     export THREAD_FUZZER_pthread_mutex_unlock_BEFORE_SLEEP_TIME_US_MAX=10000
#     export THREAD_FUZZER_pthread_mutex_unlock_AFTER_SLEEP_TIME_US_MAX=10000

#     mkdir -p /var/run/clickhouse-server
# fi

# echo "waiting for server to start"

# # Wait for the server to start, but not for too long.
# for _ in {1..100}
# do
#     clickhouse-client clickhouse://clickhouse-01:9000 --query "SELECT 1" && break
#     sleep 1
# done

# echo "Clickhouse server started!"

#setup_logs_replication
#attach_gdb_to_clickhouse

# # create tables for minio log webhooks
# clickhouse-client  clickhouse://clickhouse-01:9000 --allow_experimental_json_type=1 --query "CREATE TABLE minio_audit_logs
# (
#     log JSON(time DateTime64(9))
# )
# ENGINE = MergeTree
# ORDER BY tuple()"

# clickhouse-client clickhouse://clickhouse-01:9000 --allow_experimental_json_type=1 --query "CREATE TABLE minio_server_logs
# (
#     log JSON(time DateTime64(9))
# )
# ENGINE = MergeTree
# ORDER BY tuple()"

# create minio log webhooks for both audit and server logs
# use async inserts to avoid creating too many parts
# ./mc admin config set clickminio logger_webhook:ch_server_webhook endpoint="http://localhost:8123/?async_insert=1&wait_for_async_insert=0&async_insert_busy_timeout_min_ms=5000&async_insert_busy_timeout_max_ms=5000&async_insert_max_query_number=1000&async_insert_max_data_size=10485760&date_time_input_format=best_effort&query=INSERT%20INTO%20minio_server_logs%20FORMAT%20JSONAsObject" queue_size=1000000 batch_size=500
# ./mc admin config set clickminio audit_webhook:ch_audit_webhook endpoint="http://localhost:8123/?async_insert=1&wait_for_async_insert=0&async_insert_busy_timeout_min_ms=5000&async_insert_busy_timeout_max_ms=5000&async_insert_max_query_number=1000&async_insert_max_data_size=10485760&date_time_input_format=best_effort&query=INSERT%20INTO%20minio_audit_logs%20FORMAT%20JSONAsObject" queue_size=1000000 batch_size=500

# max_retries=100
# retry=1
# while [ $retry -le $max_retries ]; do
#     echo "clickminio restart attempt $retry:"

#     output=$(./mc admin service restart clickminio --wait --json 2>&1 | jq -r .status)
#     echo "Output of restart status: $output"

#     expected_output="success
# success"
#     if [ "$output" = "$expected_output" ]; then
#         echo "Restarted clickminio successfully."
#         break
#     fi

#     sleep 1

#     retry=$((retry + 1))
# done

# if [ $retry -gt $max_retries ]; then
#     echo "Failed to restart clickminio after $max_retries attempts."
# fi

# ./mc admin trace clickminio > /test_output/minio.log &
# MC_ADMIN_PID=$!

# function fn_exists() {
#     declare -F "$1" > /dev/null;
# }

# # FIXME: to not break old builds, clean on 2023-09-01
# function try_run_with_retry() {
#     local total_retries="$1"
#     shift

#     if fn_exists run_with_retry; then
#         run_with_retry "$total_retries" "$@"
#     else
#         "$@"
#     fi
# }

function run_tests()
{
    set -x
    # We can have several additional options so we pass them as array because it is more ideologically correct.
    read -ra ADDITIONAL_OPTIONS <<< "${ADDITIONAL_OPTIONS:-}"

    # HIGH_LEVEL_COVERAGE=YES

    # Use random order in flaky check
    if [ "$NUM_TRIES" -gt "1" ]; then
        ADDITIONAL_OPTIONS+=('--order=random')
        HIGH_LEVEL_COVERAGE=NO
    fi

    if [[ "$USE_DATABASE_REPLICATED" -eq 1 ]]; then
        ADDITIONAL_OPTIONS+=('--replicated-database')
        # Too many tests fail for DatabaseReplicated in parallel.
        ADDITIONAL_OPTIONS+=('--jobs')
        ADDITIONAL_OPTIONS+=('3')
    elif [[ 1 == $(clickhouse-client clickhouse://clickhouse-01:9000 --query "SELECT value LIKE '%SANITIZE_COVERAGE%' FROM system.build_options WHERE name = 'CXX_FLAGS'") ]]; then
        # Coverage on a per-test basis could only be collected sequentially.
        # Do not set the --jobs parameter.
        echo "Running tests with coverage collection."
    else
        # All other configurations are OK.
        ADDITIONAL_OPTIONS+=('--jobs')
        ADDITIONAL_OPTIONS+=('1')
    fi

    if [[ -n "$RUN_BY_HASH_NUM" ]] && [[ -n "$RUN_BY_HASH_TOTAL" ]]; then
        ADDITIONAL_OPTIONS+=('--run-by-hash-num')
        ADDITIONAL_OPTIONS+=("$RUN_BY_HASH_NUM")
        ADDITIONAL_OPTIONS+=('--run-by-hash-total')
        ADDITIONAL_OPTIONS+=("$RUN_BY_HASH_TOTAL")
        HIGH_LEVEL_COVERAGE=NO
    fi

    if [[ -n "$USE_DATABASE_ORDINARY" ]] && [[ "$USE_DATABASE_ORDINARY" -eq 1 ]]; then
        ADDITIONAL_OPTIONS+=('--db-engine=Ordinary')
    fi

    # if [[ "${HIGH_LEVEL_COVERAGE}" = "YES" ]]; then
    #     ADDITIONAL_OPTIONS+=('--report-coverage')
    # fi

    ADDITIONAL_OPTIONS+=('--report-logs-stats')

    #clickhouse-client clickhouse://clickhouse-01:9000 -q "insert into system.zookeeper (name, path, value) values ('auxiliary_zookeeper2', '/test/chroot/', '')"

    set +e

    TEST_ARGS=(
        --testname
        --no-stateful
        --no-shard
        --zookeeper
        --check-zookeeper-session
        --hung-check
        --print-time
        --no-drop-if-fail
        --capture-client-stacktrace
        --queries "/tests/queries"
        --test-runs "$NUM_TRIES"
        "${ADDITIONAL_OPTIONS[@]}"
    )
    clickhouse-test "${TEST_ARGS[@]}" #2>&1 \
        # | ts '%Y-%m-%d %H:%M:%S' \
        # | tee -a test_output/test_result.txt
    set -e
}

export -f run_tests

# if [ "$NUM_TRIES" -gt "1" ]; then
#     # We don't run tests with Ordinary database in PRs, only in master.
#     # So run new/changed tests with Ordinary at least once in flaky check.
#     NUM_TRIES=1 USE_DATABASE_ORDINARY=1 run_tests \
#       | sed 's/All tests have finished/Redacted: a message about tests finish is deleted/' | sed 's/No tests were run/Redacted: a message about no tests run is deleted/' ||:
# fi

run_tests ||:

# echo "Files in current directory"
# ls -la ./
# echo "Files in root directory"
# ls -la /

# clickhouse-client -q "system flush logs" ||:

# stop logs replication to make it possible to dump logs tables via clickhouse-local
# stop_logs_replication

# logs_saver_client_options="--max_block_size 8192 --max_memory_usage 10G --max_threads 1 --max_result_rows 0 --max_result_bytes 0 --max_bytes_to_read 0"

# # Try to get logs while server is running
# failed_to_save_logs=0
# for table in query_log zookeeper_log trace_log transactions_info_log metric_log blob_storage_log error_log
# do
#     if ! clickhouse-client ${logs_saver_client_options} -q "select * from system.$table into outfile '/test_output/$table.tsv.zst' format TSVWithNamesAndTypes"; then
#         failed_to_save_logs=1
#     fi
#     if [[ "$USE_DATABASE_REPLICATED" -eq 1 ]]; then
#         if ! clickhouse-client ${logs_saver_client_options} --port 19000 -q "select * from system.$table into outfile '/test_output/$table.1.tsv.zst' format TSVWithNamesAndTypes"; then
#             failed_to_save_logs=1
#         fi
#         if ! clickhouse-client ${logs_saver_client_options} --port 29000 -q "select * from system.$table into outfile '/test_output/$table.2.tsv.zst' format TSVWithNamesAndTypes"; then
#             failed_to_save_logs=1
#         fi
#     fi

#     if [[ "$USE_SHARED_CATALOG" -eq 1 ]]; then
#         if ! clickhouse-client ${logs_saver_client_options} --port 29000 -q "select * from system.$table into outfile '/test_output/$table.2.tsv.zst' format TSVWithNamesAndTypes"; then
#             failed_to_save_logs=1
#         fi
#     fi
# done


# collect minio audit and server logs
# wait for minio to flush its batch if it has any
# sleep 1
# clickhouse-client -q "SYSTEM FLUSH ASYNC INSERT QUEUE" ||:
# clickhouse-client ${logs_saver_client_options} -q "SELECT log FROM minio_audit_logs ORDER BY log.time INTO OUTFILE '/test_output/minio_audit_logs.jsonl.zst' FORMAT JSONEachRow" ||:
# clickhouse-client ${logs_saver_client_options} -q "SELECT log FROM minio_server_logs ORDER BY log.time INTO OUTFILE '/test_output/minio_server_logs.jsonl.zst' FORMAT JSONEachRow" ||:

# Stop server so we can safely read data with clickhouse-local.
# Why do we read data with clickhouse-local?
# Because it's the simplest way to read it when server has crashed.
# sudo clickhouse stop ||:


# if [[ "$USE_DATABASE_REPLICATED" -eq 1 ]]; then
#     sudo clickhouse stop --pid-path /var/run/clickhouse-server1 ||:
#     sudo clickhouse stop --pid-path /var/run/clickhouse-server2 ||:
# fi

# if [[ "$USE_SHARED_CATALOG" -eq 1 ]]; then
#     sudo clickhouse stop --pid-path /var/run/clickhouse-server1 ||:
# fi

# # Kill minio admin client to stop collecting logs
# kill $MC_ADMIN_PID

# rg -Fa "<Fatal>" /var/log/clickhouse-server/clickhouse-server.log ||:
# rg -A50 -Fa "============" /var/log/clickhouse-server/stderr.log ||:
# zstd --threads=0 < /var/log/clickhouse-server/clickhouse-server.log > /test_output/clickhouse-server.log.zst &

# data_path_config="--path=/var/lib/clickhouse/"
# if [[ -n "$USE_S3_STORAGE_FOR_MERGE_TREE" ]] && [[ "$USE_S3_STORAGE_FOR_MERGE_TREE" -eq 1 ]]; then
#     # We need s3 storage configuration (but it's more likely that clickhouse-local will fail for some reason)
#     data_path_config="--config-file=/etc/clickhouse-server/config.xml"
# fi


# # If server crashed dump system logs with clickhouse-local
# if [ $failed_to_save_logs -ne 0 ]; then
#     # Compress tables.
#     #
#     # NOTE:
#     # - that due to tests with s3 storage we cannot use /var/lib/clickhouse/data
#     #   directly
#     # - even though ci auto-compress some files (but not *.tsv) it does this only
#     #   for files >64MB, we want this files to be compressed explicitly
#     for table in query_log zookeeper_log trace_log transactions_info_log metric_log blob_storage_log error_log
#     do
#         clickhouse-local ${logs_saver_client_options} "$data_path_config" --only-system-tables --stacktrace -q "select * from system.$table format TSVWithNamesAndTypes" | zstd --threads=0 > /test_output/$table.tsv.zst ||:

#         if [[ "$USE_DATABASE_REPLICATED" -eq 1 ]]; then
#             clickhouse-local ${logs_saver_client_options} --path /var/lib/clickhouse1/ --only-system-tables --stacktrace -q "select * from system.$table format TSVWithNamesAndTypes" | zstd --threads=0 > /test_output/$table.1.tsv.zst ||:
#             clickhouse-local ${logs_saver_client_options} --path /var/lib/clickhouse2/ --only-system-tables --stacktrace -q "select * from system.$table format TSVWithNamesAndTypes" | zstd --threads=0 > /test_output/$table.2.tsv.zst ||:
#         fi

#         if [[ "$USE_SHARED_CATALOG" -eq 1 ]]; then
#             clickhouse-local ${logs_saver_client_options} --path /var/lib/clickhouse1/ --only-system-tables --stacktrace -q "select * from system.$table format TSVWithNamesAndTypes" | zstd --threads=0 > /test_output/$table.1.tsv.zst ||:
#         fi
#     done
# fi

# # Also export trace log in flamegraph-friendly format.
# for trace_type in CPU Memory Real
# do
#     clickhouse-local "$data_path_config" --only-system-tables -q "
#             select
#                 arrayStringConcat((arrayMap(x -> concat(splitByChar('/', addressToLine(x))[-1], '#', demangle(addressToSymbol(x)) ), trace)), ';') AS stack,
#                 count(*) AS samples
#             from system.trace_log
#             where trace_type = '$trace_type'
#             group by trace
#             order by samples desc
#             settings allow_introspection_functions = 1
#             format TabSeparated" \
#         | zstd --threads=0 > "/test_output/trace-log-$trace_type-flamegraph.tsv.zst" ||:
# done

# # Grep logs for sanitizer asserts, crashes and other critical errors
# check_logs_for_critical_errors

# # Check test_result.txt with test results and test_results.tsv generated by grepping logs before
# /repo/tests/docker_scripts/process_functional_tests_result.py || echo -e "failure\tCannot parse results" > /test_output/check_status.tsv


# # Compressed (FIXME: remove once only github actions will be left)
# rm /var/log/clickhouse-server/clickhouse-server.log
# mv /var/log/clickhouse-server/stderr.log /test_output/ ||:
# if [[ -n "$WITH_COVERAGE" ]] && [[ "$WITH_COVERAGE" -eq 1 ]]; then
#     tar --zstd -chf /test_output/clickhouse_coverage.tar.zst /profraw ||:
# fi

# tar -chf /test_output/coordination.tar /var/lib/clickhouse/coordination ||:

# rm -rf /var/lib/clickhouse/data/system/*/
# tar -chf /test_output/store.tar /var/lib/clickhouse/store ||:
# tar -chf /test_output/metadata.tar /var/lib/clickhouse/metadata/*.sql ||:


# if [[ "$USE_DATABASE_REPLICATED" -eq 1 ]]; then
#     rg -Fa "<Fatal>" /var/log/clickhouse-server/clickhouse-server1.log ||:
#     rg -Fa "<Fatal>" /var/log/clickhouse-server/clickhouse-server2.log ||:
#     zstd --threads=0 < /var/log/clickhouse-server/clickhouse-server1.log > /test_output/clickhouse-server1.log.zst ||:
#     zstd --threads=0 < /var/log/clickhouse-server/clickhouse-server2.log > /test_output/clickhouse-server2.log.zst ||:
#     mv /var/log/clickhouse-server/stderr1.log /test_output/ ||:
#     mv /var/log/clickhouse-server/stderr2.log /test_output/ ||:
#     tar -chf /test_output/coordination1.tar /var/lib/clickhouse1/coordination ||:
#     tar -chf /test_output/coordination2.tar /var/lib/clickhouse2/coordination ||:
# fi

# if [[ "$USE_SHARED_CATALOG" -eq 1 ]]; then
#     rg -Fa "<Fatal>" /var/log/clickhouse-server/clickhouse-server1.log ||:
#     zstd --threads=0 < /var/log/clickhouse-server/clickhouse-server1.log > /test_output/clickhouse-server1.log.zst ||:
#     mv /var/log/clickhouse-server/stderr1.log /test_output/ ||:
#     tar -chf /test_output/coordination1.tar /var/lib/clickhouse1/coordination ||:
# fi

# collect_core_dumps