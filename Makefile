# Copyright 2017-2020 Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

REGISTRY ?= quay.io/cilium

RHCONNECT_CERTIFICATION_REGISTRY_PREFIX_FOR_CILIUM_OLM_OPERATOR_IMAGE := scan.connect.redhat.com/ospid-104ec1da-384c-4d7c-bd27-9dbfd8377f5b
RHCONNECT_CERTIFICATION_REGISTRY_PREFIX_FOR_CILIUM_OLM_OPERATOR_BUNDLE_IMAGE := scan.connect.redhat.com/ospid-014467d6-a0b5-4ec3-9ea7-059f24661a7a

PUSH ?= false

GOBIN = $(shell go env GOPATH)/bin

IMAGINE ?= $(GOBIN)/imagine
KG ?= $(GOBIN)/kg

OPM ?= $(GOBIN)/opm

ifeq ($(MAKER_CONTAINER),true)
  IMAGINE=imagine
  KG=kg
endif

images.all: lint
	@echo "Current image tags:"
	@cat *.tag

images.%.all:
	@echo "Current image tags:"
	@cat *.tag

include Makefile.releases

lint:
	scripts/lint.sh

.buildx_builder:
	docker buildx create --platform linux/amd64 > $@

images.operator.v%: .buildx_builder
	$(IMAGINE) build \
		--builder=$$(cat .buildx_builder) \
		--base=./operator/cilium.v$(cilium_version) \
		--name=cilium-olm \
		--custom-tag-suffix=v$(cilium_version) \
		--registry=$(REGISTRY) \
		--registry=$(RHCONNECT_CERTIFICATION_REGISTRY_PREFIX_FOR_CILIUM_OLM_OPERATOR_IMAGE) \
		--push=$(PUSH)
	$(IMAGINE) image \
		--base=./operator/cilium.v$(cilium_version) \
		--name=cilium-olm \
		--custom-tag-suffix=v$(cilium_version) \
		--registry=$(REGISTRY) \
		--registry=$(RHCONNECT_CERTIFICATION_REGISTRY_PREFIX_FOR_CILIUM_OLM_OPERATOR_IMAGE) \
		> image-cilium-olm-v$(cilium_version).tag

images.operator-bundle.v%: .buildx_builder
	$(IMAGINE) build \
		--builder=$$(cat .buildx_builder) \
		--base=./bundles/cilium.v$(cilium_version) \
		--dockerfile=../Dockerfile \
		--name=cilium-olm-bundle \
		--custom-tag-suffix=v$(cilium_version) \
		--registry=$(REGISTRY) \
		--registry=$(RHCONNECT_CERTIFICATION_REGISTRY_PREFIX_FOR_CILIUM_OLM_OPERATOR_BUNDLE_IMAGE) \
		--push=$(PUSH)
	$(IMAGINE) image \
		--base=./bundles/cilium.v$(cilium_version) \
		--name=cilium-olm-bundle \
		--custom-tag-suffix=v$(cilium_version) \
		--registry=$(REGISTRY) \
		--registry=$(RHCONNECT_CERTIFICATION_REGISTRY_PREFIX_FOR_CILIUM_OLM_OPERATOR_BUNDLE_IMAGE) \
		> image-cilium-olm-bundle-v$(cilium_version).tag

generate.bundles.v%:
	scripts/generate-bundle.sh "image-cilium-olm-v$(cilium_version).tag" "$(cilium_version)"

validate.bundles.v%:
	$(OPM) alpha bundle validate --tag "$$(cat image-cilium-olm-bundle-v$(cilium_version).tag | head -1)"
