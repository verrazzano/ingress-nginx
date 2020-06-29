# Build Instructions

The base tag this release is branched from is `controller-0.32.0`


Create Environment Variables

```
export DOCKER_REPO=<Docker Repository>
export DOCKER_NAMESPACE=<Docker Namespace>
export DOCKER_TAG=<Image Tag>
```

Build and Push Images

```
# Build and push ingress-nginx

mkdir -p ${GOPATH}/src/k8s.io
ln -s `pwd`/ ${GOPATH}/src/k8s.io/ingress-nginx
cd ${GOPATH}/src/k8s.io/ingress-nginx
# We need keep this follow line here, otherwise, the final docker image will contain github credential!!!
git remote set-url origin 	https://github.com/verrazzano/ingress-nginx.git
# Build nginx and its modules from source, and use that as a base image of ingress-nginx
docker build --rm=true --tag=${DOCKER_REPO}/${DOCKER_NAMESPACE}/ingress-nginx:${DOCKER_TAG} -f images/nginx/rootfs/Dockerfile.ol8-slim images/nginx/rootfs/
docker push ${DOCKER_REPO}/${DOCKER_NAMESPACE}/ingress-nginx:${DOCKER_TAG}


# Build and push custom-error-pages

make build container -e BASEIMAGE=${DOCKER_REPO}/${DOCKER_NAMESPACE}/ingress-nginx:${DOCKER_TAG} -e TAG=${DOCKER_TAG} -e REGISTRY=${DOCKER_REPO} -C images/custom-error-pages/
docker push ${DOCKER_REPO}/${DOCKER_NAMESPACE}/custom-error-pages:${DOCKER_TAG}
```