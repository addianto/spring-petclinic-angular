ARG DOCKER_HUB="docker.io"
ARG NGINX_VERSION="1.24.0-alpine"
ARG NODE_VERSION="16.14.2-alpine"

FROM $DOCKER_HUB/library/node:$NODE_VERSION AS build

COPY . /workspace/

ARG NPM_REGISTRY=" https://registry.npmjs.org"
ARG REST_API_URL="http://localhost:9966/petclinic/api/"
ARG NG_BUILD_CONFIGURATION="production"

WORKDIR /workspace/

RUN echo "registry = \"$NPM_REGISTRY\"" > .npmrc                                                            && \
    sed -i.bak "s#http://localhost:9966/petclinic/api/#$REST_API_URL#" src/environments/environment.ts      && \
    sed -i.bak "s#http://localhost:9966/petclinic/api/#$REST_API_URL#" src/environments/environment.prod.ts && \
    npm install                                                                                             && \
    npm run build --if-present -- --configuration "$NG_BUILD_CONFIGURATION"

FROM $DOCKER_HUB/nginxinc/nginx-unprivileged:$NGINX_VERSION AS runtime

COPY --from=build /workspace/dist/ /usr/share/nginx/html/
COPY --chown=nginx ./deploy/nginx-unprivileged.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK CMD curl --fail http://localhost:8080 || exit 1
