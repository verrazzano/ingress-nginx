#!/bin/bash

# Copyright (C) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

CONTROLLER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-nginx-ingress-controller}
BACKEND_IMAGE_NAME=${DOCKER_DEFAULT_BACKEND_IMAGE_NAME:-nginx-ingress-default-backend}

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
INGRESS_NGINX_DOCKER_BASE_IMAGE=${DOCKER_REPO}/${DOCKER_NAMESPACE}/nginx-ingress
INGRESS_NGINX_DOCKER_IMAGE_AMD64=${DOCKER_REPO}/${DOCKER_NAMESPACE}/nginx-ingress-amd64:${DOCKER_TAG}
DEFAULT_BACKEND_IMAGE=${DOCKER_REPO}/${DOCKER_NAMESPACE}/${BACKEND_IMAGE_NAME}
CONTROLLER_IMAGE=${DOCKER_REPO}/${DOCKER_NAMESPACE}/${CONTROLLER_IMAGE_NAME}

set -ue

mkdir -p ${GOPATH}/src/k8s.io
ln -f -s "${SCRIPT_DIR}"/ "${GOPATH}"/src/k8s.io/ingress-nginx
cd "${GOPATH}"/src/k8s.io/ingress-nginx
# We need keep this follow line here, otherwise, the final docker image will contain github credential!!!
git remote set-url origin 	https://github.com/verrazzano/ingress-nginx.git


# Build nginx and its modules from source, and use that as a base image of ingress-nginx
mkdir -p images/nginx/rootfs/stage-licenses
cp LICENSE README.md THIRD_PARTY_LICENSES.txt images/nginx/rootfs/stage-licenses
docker build --rm=true --tag=${INGRESS_NGINX_DOCKER_IMAGE_AMD64} -f images/nginx/rootfs/Dockerfile images/nginx/rootfs/
rm -fr images/nginx/rootfs/stage-licenses

# Push nginx so it can be used as a base image of ingress-nginx
docker push ${INGRESS_NGINX_DOCKER_IMAGE_AMD64}

# Build custom-error-pages and its modules from source
mkdir -p images/custom-error-pages/rootfs/stage-licenses
cp LICENSE README.md THIRD_PARTY_LICENSES.txt images/custom-error-pages/rootfs/stage-licenses
make build container -e BASEIMAGE=${INGRESS_NGINX_DOCKER_IMAGE_AMD64} -e TAG=${DOCKER_TAG} -e REGISTRY=${DOCKER_REPO}/${DOCKER_NAMESPACE} -C images/custom-error-pages/
rm -fr images/custom-error-pages/rootfs/stage-licenses

# Push the custom-error-pages image
docker tag ${DOCKER_REPO}/${DOCKER_NAMESPACE}/custom-error-pages:${DOCKER_TAG} ${DEFAULT_BACKEND_IMAGE}:${DOCKER_TAG}
docker push ${DEFAULT_BACKEND_IMAGE}:${DOCKER_TAG}

# Create the nginx-ingress-controller image
make ARCH=amd64 build container -e BASE_IMAGE=${INGRESS_NGINX_DOCKER_BASE_IMAGE} -e BASE_TAG=${DOCKER_TAG} -e TAG=${DOCKER_TAG} -e REGISTRY=${DOCKER_REPO}/${DOCKER_NAMESPACE} USE_DOCKER=false DIND_TASKS=false
docker tag ${CONTROLLER_IMAGE}-amd64:${DOCKER_TAG} ${CONTROLLER_IMAGE}:${DOCKER_TAG}
docker push ${CONTROLLER_IMAGE}:${DOCKER_TAG}

# Remove symlink
cd "${SCRIPT_DIR}"
rm "${GOPATH}"/src/k8s.io/ingress-nginx
