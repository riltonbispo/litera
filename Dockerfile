# syntax=docker/dockerfile:1

ARG RUBY_VERSION=4.0.5
ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-bookworm-slim AS node

FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      libjemalloc2 \
      libpq-dev \
      libpq5 \
      libyaml-dev \
      pkg-config \
      postgresql-client \
      sqlite3 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    LD_PRELOAD=/usr/local/lib/libjemalloc.so

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
