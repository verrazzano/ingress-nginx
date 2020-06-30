
# Build and push ingress-nginx

mkdir -p ${GOPATH}/src/k8s.io
ln -f -s `pwd`/ ${GOPATH}/src/k8s.io/ingress-nginx
cd ${GOPATH}/src/k8s.io/ingress-nginx
# We need keep this follow line here, otherwise, the final docker image will contain github credential!!!
git remote set-url origin 	https://github.com/verrazzano/ingress-nginx.git


# Build nginx and its modules from source, and use that as a base image of ingress-nginx

mkdir -p images/nginx/rootfs/stage-licenses
cp LICENSE README.md THIRD_PARTY_LICENSES.txt images/nginx/rootfs/stage-licenses
docker build --rm=true --tag=${DOCKER_REPO}/${DOCKER_NAMESPACE}/ingress-nginx:${DOCKER_TAG} -f images/nginx/rootfs/Dockerfile.ol8-slim images/nginx/rootfs/
rm -fr images/nginx/rootfs/stage-licenses


mkdir -p images/custom-error-pages/rootfs/stage-licenses
cp LICENSE README.md THIRD_PARTY_LICENSES.txt images/custom-error-pages/rootfs/stage-licenses
make build container -e BASEIMAGE=${DOCKER_REPO}/${DOCKER_NAMESPACE}/ingress-nginx:${DOCKER_TAG} -e TAG=${DOCKER_TAG} -e REGISTRY=${DOCKER_REPO} -C images/custom-error-pages/
rm -fr images/custom-error-pages/rootfs/stage-licenses
