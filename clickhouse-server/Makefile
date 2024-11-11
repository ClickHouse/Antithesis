flavor ?=
image_suffix = $(if $(flavor),-$(flavor))
package_suffix = $(if $(flavor),_$(flavor),_release)
version ?= 24.11.1.1178
version_suffix = $(if $(flavor),%2B$(flavor))
full_version = $(version)$(version_suffix)
commit ?= 506b30fd4997c11273567cb96410fc0324d3bb12
major = $(word 1, $(subst ., ,$(version)))
minor = $(word 2, $(subst ., ,$(version)))
url = https://s3.amazonaws.com/clickhouse-builds/$(major).$(minor)/$(commit)/package$(package_suffix)
docker_registry = us-central1-docker.pkg.dev/molten-verve-216720/clickhouse-repository

# Make sure to disable ASLR when generating the TSAN flavor. Otherwise, clickhouse-server will throw
# an error when trying to install it:
# ==135==WARNING: ThreadSanitizer: memory layout is incompatible, possibly due to high-entropy ASLR.
# Re-execing with fixed virtual address space.
# N.B. reducing ASLR entropy is preferable.
# ThreadSanitizer: CHECK failed: tsan_platform_linux.cpp:282 "((personality(old_personality | ADDR_NO_RANDOMIZE))) != ((-1))" (0xffffffffffffffff, 0xffffffffffffffff) (tid=135)
# Segmentation fault (core dumped)

all: build

build: ## Build the docker image
	docker build . -t clickhouse-server$(image_suffix):$(version) --build-arg VERSION="$(full_version)" --build-arg deb_location_url="$(url)"
	docker tag clickhouse-server$(image_suffix):$(version) $(docker_registry)/clickhouse-server$(image_suffix):$(version)

tag-latest: build ## Tag the docker image as the latest
	docker tag clickhouse-server$(image_suffix):$(version) clickhouse-server$(image_suffix):latest
	docker tag clickhouse-server$(image_suffix):$(version) $(docker_registry)/clickhouse-server$(image_suffix):latest

push: ## Push the docker image
	docker push $(docker_registry)/clickhouse-server$(image_suffix):$(version)

push-latest: tag-latest push ## Push the latest image
	docker push $(docker_registry)/clickhouse-server$(image_suffix):latest

.PHONY: %

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
