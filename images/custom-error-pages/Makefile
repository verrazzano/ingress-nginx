# Copyright (C) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

all: all-container

BUILDTAGS=

# Use the 0.0 tag for testing, it shouldn't clobber any release builds
TAG?=0.4
REGISTRY?=quay.io/kubernetes-ingress-controller
GOOS?=linux
DOCKER?=docker
SED_I?=sed -i
GOHOSTOS ?= $(shell go env GOHOSTOS)

PKG=k8s.io/ingress-nginx/images/custom-error-pages

ifeq ($(GOHOSTOS),darwin)
  SED_I=sed -i ''
endif

REPO_INFO=$(shell git config --get remote.origin.url)

ifndef COMMIT
  COMMIT := git-$(shell git rev-parse --short HEAD)
endif

ARCH ?= $(shell go env GOARCH)
GOARCH = ${ARCH}

BASEIMAGE?=container-registry.oracle.com/os/oraclelinux:7-slim@sha256:9b86d1332a883ee8f68dd44ba42133de518b2e0ec1cc70257e59fb4da86b1ad3

ALL_ARCH = amd64 arm arm64

QEMUVERSION=v4.1.0-1

IMGNAME = custom-error-pages
IMAGE = $(REGISTRY)/$(IMGNAME)
MULTI_ARCH_IMG = $(IMAGE)-$(ARCH)

ifeq ($(ARCH),arm)
    QEMUARCH=arm
	GOARCH=arm
endif
ifeq ($(ARCH),arm64)
	QEMUARCH=aarch64
endif

TEMP_DIR := $(shell mktemp -d)

DOCKERFILE := $(TEMP_DIR)/rootfs/Dockerfile

sub-container-%:
	$(MAKE) ARCH=$* build container

sub-push-%:
	$(MAKE) ARCH=$* push

all-container: $(addprefix sub-container-,$(ALL_ARCH))

all-push: $(addprefix sub-push-,$(ALL_ARCH))

container: .container-$(ARCH)
.container-$(ARCH):
	cp -r ./* $(TEMP_DIR)
	$(SED_I) 's|BASEIMAGE|$(BASEIMAGE)|g' $(DOCKERFILE)
	$(SED_I) "s|QEMUARCH|$(QEMUARCH)|g" $(DOCKERFILE)

ifeq ($(ARCH),amd64)
	# When building "normally" for amd64, remove the whole line, it has no part in the amd64 image
	$(SED_I) "/CROSS_BUILD_/d" $(DOCKERFILE)
else
	# When cross-building, only the placeholder "CROSS_BUILD_" should be removed
	# Register /usr/bin/qemu-ARCH-static as the handler for ARM binaries in the kernel
	# $(DOCKER) run --rm --privileged multiarch/qemu-user-static:register --reset
	curl -sSL https://github.com/multiarch/qemu-user-static/releases/download/$(QEMUVERSION)/x86_64_qemu-$(QEMUARCH)-static.tar.gz | tar -xz -C $(TEMP_DIR)/rootfs
	$(SED_I) "s/CROSS_BUILD_//g" $(DOCKERFILE)
endif

	$(DOCKER) build -t $(MULTI_ARCH_IMG):$(TAG) $(TEMP_DIR)/rootfs

ifeq ($(ARCH), amd64)
	# This is for to maintain the backward compatibility
	$(DOCKER) tag $(MULTI_ARCH_IMG):$(TAG) $(IMAGE):$(TAG)
endif

push: .push-$(ARCH)
.push-$(ARCH):
	$(DOCKER) push $(MULTI_ARCH_IMG):$(TAG)
ifeq ($(ARCH), amd64)
	$(DOCKER) push $(IMAGE):$(TAG)
endif

clean:
	$(DOCKER) rmi -f $(MULTI_ARCH_IMG):$(TAG) || true

build: clean
	CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -a -installsuffix cgo \
		-ldflags "-s -w" \
		-o ${TEMP_DIR}/rootfs/custom-error-pages ${PKG}/...

release: all-container all-push
	echo "done"

.PHONY: register-qemu
register-qemu:
	# Register /usr/bin/qemu-ARCH-static as the handler for binaries in multiple platforms
	$(DOCKER) run --rm --privileged multiarch/qemu-user-static:register --reset
