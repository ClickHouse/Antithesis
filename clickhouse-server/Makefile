flavor = tsan
version = 24.11.1.1178%2B$(flavor)
url = https://s3.amazonaws.com/clickhouse-builds/24.11/506b30fd4997c11273567cb96410fc0324d3bb12/package_$(flavor)
docker_registry = us-central1-docker.pkg.dev/molten-verve-216720/clickhouse-repository/

all:
	docker build . -t clickhouse-server-$(flavor):latest --build-arg VERSION="$(version)" --build-arg deb_location_url="$(url)"
	docker tag clickhouse-server-$(flavor) $(docker_registry)/clickhouse-server-$(flavor):latest

push:
	docker push $(docker_registry)/clickhouse-server-$(flavor):latest

.PHONY: %
