# Build Instructions

The base tag this release is branched from is `controller-0.32.0`

## Set Environment Variables

```
export DOCKER_REPO=<Docker Repository>
export DOCKER_NAMESPACE=<Docker Namespace>
export DOCKER_TAG=<Image Tag>
```

## Build and Push Images

```
./build-images.sh
docker push ${DOCKER_REPO}/${DOCKER_NAMESPACE}/ingress-nginx:${DOCKER_TAG}
docker push ${DOCKER_REPO}/${DOCKER_NAMESPACE}/custom-error-pages:${DOCKER_TAG}
```
