ARG PUBLIC_PATH=//www.pkuru.com/
FROM node:22-bullseye-slim AS builder
ARG PUBLIC_PATH

ARG API_ENDPOINT=http://rl:4555/graphql

# log most things
ENV NPM_CONFIG_LOGLEVEL=notice

# OS packages for compilation
RUN apt update
RUN apt install -y make g++ git
# RUN apt-get update && apt-get install -y wget make g++ zlib1g-dev
# RUN wget https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz && tar xvf Python-3.6.9.tgz && cd Python-3.6.9 && ./configure --enable-optimizations --enable-shared && make -j8 && make altinstall
# RUN corepack enable && yarn init -2 && yarn set version stable
RUN corepack enable

# install NPM packages
WORKDIR /build
# add source
COPY package*.json ./
COPY yarn.lock ./
COPY .yarnrc.yml ./
# COPY node_modules ./node_modules
RUN yarn install --network-timeout 1000000000

COPY . .

ENV PUBLIC_PATH=$PUBLIC_PATH
ENV NODE_ENV=production
ENV VITE_API_ENDPOINT=$API_ENDPOINT

# build
RUN yarn rescript build
RUN yarn dev:vite:server-fix # This fixes the imports in node_modules
RUN yarn rescript-relay-compiler
RUN yarn build:client
RUN yarn build:server

########################

FROM node:22-bullseye-slim
ARG PUBLIC_PATH

WORKDIR /app

# copy source + compiled `node_modules` 
COPY --from=builder /build .

EXPOSE 3000

ENV PUBLIC_PATH=$PUBLIC_PATH
# by default, run in production mode
RUN corepack enable
CMD yarn production

