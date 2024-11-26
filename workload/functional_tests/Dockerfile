FROM docker.io/clickhouse/clickhouse-server:latest
RUN apt update && apt install -y python3 python3-venv zip git curl expect mysql-client python3-pip

# gdb and lldb
RUN apt update && apt install gdb lldb -y

COPY requirements.txt /
RUN pip3 install --upgrade pip
RUN python3 -m venv /.e && bash -c "source /.e/bin/activate && pip3 install --no-cache-dir -r /requirements.txt"

# this folder is from the clickhouse source code
COPY /tests /tests
COPY /scripts /scripts
COPY /utils /utils
COPY ./entrypoint.sh /entrypoint.sh
#COPY ./stateful_runner.sh stateful_runner.sh
COPY ./parallel_driver_stateless_runner.sh /opt/antithesis/test/v1/stateless/parallel_driver_stateless_runner.sh
#COPY ./parallel_driver_stateful_runner.sh /opt/antithesis/test/v1/stateful/parallel_driver_stateful_runner.sh
ENTRYPOINT ./entrypoint.sh