flavor = tsan
version = 24.11.1.1178%2B$(flavor)
url = https://s3.amazonaws.com/clickhouse-builds/24.11/506b30fd4997c11273567cb96410fc0324d3bb12/package_$(flavor)
docker_registry = us-central1-docker.pkg.dev/molten-verve-216720/clickhouse-repository

# Make sure to disable ASLR when generating the TSAN flavor. Otherwise, clickhouse-server will throw
# an error when trying to install it:
# ==135==WARNING: ThreadSanitizer: memory layout is incompatible, possibly due to high-entropy ASLR.
# Re-execing with fixed virtual address space.
# N.B. reducing ASLR entropy is preferable.
# ThreadSanitizer: CHECK failed: tsan_platform_linux.cpp:282 "((personality(old_personality | ADDR_NO_RANDOMIZE))) != ((-1))" (0xffffffffffffffff, 0xffffffffffffffff) (tid=135)
# Segmentation fault (core dumped)

all:
	docker build . -t clickhouse-server-$(flavor):latest --build-arg VERSION="$(version)" --build-arg deb_location_url="$(url)"
	docker tag clickhouse-server-$(flavor) $(docker_registry)/clickhouse-server-$(flavor):latest

push:
	docker push $(docker_registry)/clickhouse-server-$(flavor):latest

.PHONY: %
