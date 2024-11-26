flavor ?=
image_suffix = $(if $(flavor),-$(flavor))
package_suffix = $(if $(flavor),_$(flavor),_release)
version ?= 24.12.1.315
version_suffix = $(if $(flavor),%2B$(flavor))
full_version = $(version)$(version_suffix)
url = https://s3.amazonaws.com/clickhouse-builds/24.12/37cd1623970ac864fb00d999820f8d61be057024/package$(package_suffix)
docker_registry = us-central1-docker.pkg.dev/molten-verve-216720/clickhouse-repository

# Make sure to disable ASLR when generating the TSAN flavor. Otherwise, clickhouse-server will throw
# an error when trying to install it:
# ==135==WARNING: ThreadSanitizer: memory layout is incompatible, possibly due to high-entropy ASLR.
# Re-execing with fixed virtual address space.
# N.B. reducing ASLR entropy is preferable.
# ThreadSanitizer: CHECK failed: tsan_platform_linux.cpp:282 "((personality(old_personality | ADDR_NO_RANDOMIZE))) != ((-1))" (0xffffffffffffffff, 0xffffffffffffffff) (tid=135)
# Segmentation fault (core dumped)

all: build-clickhouse-server

# clickhouse-server
build-clickhouse-server: ## Build the server image
push-clickhouse-server: ## Tag the server image as the latest
push-clickhouse-server: ## Push the server image
push-clickhouse-server-latest: ## Push the server latest image

# clickhouse-keeper
build-keeper-server: ## Build the keeper image
push-keeper-server: ## Tag the keeper image as the latest
push-keeper-server: ## Push the keeper image
push-keeper-server-latest: ## Push the keeper latest image

# $* here matches the wildcard that matches the % pattern
# e.g. for `build-clickhouse-server`, $* = `clickhouse-server`
build-%:
	docker build $* -t $*$(image_suffix):$(version) --build-arg VERSION="$(full_version)" --build-arg deb_location_url="$(url)"
	docker tag $*$(image_suffix):$(version) $(docker_registry)/$*$(image_suffix):$(version)

tag-%-latest: build-%
	docker tag $*$(image_suffix):$(version) $*$(image_suffix):latest
	docker tag $*$(image_suffix):$(version) $(docker_registry)/$*$(image_suffix):latest

push-%: build-%
	docker push $(docker_registry)/$*$(image_suffix):$(version)

push-%-latest: tag-%-latest push-%
	docker push $(docker_registry)/$*$(image_suffix):latest

.PHONY: build-% tag-%-latest push-% push-%-latest

build-config: ## Build the workload image
	docker build config -t clickhouse-config$(image_suffix):$(version) --build-arg FLAVOR="$(image_suffix)"
	docker tag clickhouse-config$(image_suffix):$(version) $(docker_registry)/clickhouse-config$(image_suffix):$(version)

tag-config-latest: build-config ## Tag the workload image as the latest
	docker tag clickhouse-config$(image_suffix):$(version) clickhouse-config$(image_suffix):latest
	docker tag clickhouse-config$(image_suffix):$(version) $(docker_registry)/clickhouse-config$(image_suffix):latest

push-config: build-config ## Push the workload image
	docker push $(docker_registry)/clickhouse-config$(image_suffix):$(version)

push-config-latest: tag-config-latest push-config ## Push the workload latest image
	docker push $(docker_registry)/clickhouse-config$(image_suffix):latest

build-workload: ## Build the workload image
	docker build workload/functional_tests -t functional_workload:$(version)
	docker tag functional_workload:$(version) $(docker_registry)/functional_workload:$(version)

tag-workload-latest: build-workload ## Tag the workload image as the latest
	docker tag functional_workload:$(version) functional_workload:latest
	docker tag functional_workload:$(version) $(docker_registry)/functional_workload:$(version)

push-workload: build-workload ## Push the workload image
	docker push $(docker_registry)/functional_workload:$(version)

push-workload-latest: tag-workload-latest push-workload ## Push the workload latest image
	docker push $(docker_registry)/functional_workload:latest

.PHONY: build-workload tag-workload-test push-workload push-workload-latest

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo "e.g. make push-clickhouse-server-latest flavor=tsan"
