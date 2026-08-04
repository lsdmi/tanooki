# syntax=docker/dockerfile:1
# check=skip

# Debian Bookworm ships libvips 8.14+, required by Rails 8.0.5.1 Active Storage.
# App Platform uses this Dockerfile instead of buildpacks when present.
ARG RUBY_VERSION=3.4.9
FROM docker.io/library/ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 libvips42 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT=true

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libvips-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

ARG SECRET_KEY_BASE=dummy
ARG STORAGE_ACCESS_KEY
ARG STORAGE_SECRET_KEY
ARG STORAGE_BUCKET
ARG STORAGE_REGION
ARG STORAGE_ENDPOINT
ARG ASSET_HOST

ENV SECRET_KEY_BASE=$SECRET_KEY_BASE \
    STORAGE_ACCESS_KEY=$STORAGE_ACCESS_KEY \
    STORAGE_SECRET_KEY=$STORAGE_SECRET_KEY \
    STORAGE_BUCKET=$STORAGE_BUCKET \
    STORAGE_REGION=$STORAGE_REGION \
    STORAGE_ENDPOINT=$STORAGE_ENDPOINT \
    ASSET_HOST=$ASSET_HOST

RUN bundle exec rails assets:deploy

FROM base

ENV LD_PRELOAD=libjemalloc.so.2

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

EXPOSE 8080
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]
