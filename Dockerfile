# syntax=docker/dockerfile:1
# check=skip

# Debian Bookworm ships libvips 8.14+, required by Rails 8.0.5.1 Active Storage.
# DigitalOcean App Platform builds all components from this file (dockerfile_path: Dockerfile).
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

# App Platform build-time env vars must be declared as ARG (Kaniko does not see undeclared vars).
# Dummy defaults allow local `docker build`; DO injects real values at deploy.
ARG SECRET_KEY_BASE=dummy
ARG DB_HOST=127.0.0.1
ARG DB_PORT=3306
ARG DB_NAME=dummy
ARG DB_USER=dummy
ARG DB_PASSWORD=dummy
ARG MAILER_PASSWORD=dummy
ARG OPENSEARCH_URL=http://127.0.0.1:9200
ARG OPENSEARCH_USER=dummy
ARG OPENSEARCH_PASSWORD=dummy
ARG OPENSEARCH_CA_CERT=
ARG GOOGLE_CLIENT_ID=dummy
ARG GOOGLE_CLIENT_SECRET=dummy
ARG TELEGRAM_KEY=dummy
ARG STORAGE_ACCESS_KEY
ARG STORAGE_SECRET_KEY
ARG STORAGE_BUCKET
ARG STORAGE_REGION
ARG STORAGE_ENDPOINT
ARG ASSET_HOST

ENV SECRET_KEY_BASE=$SECRET_KEY_BASE \
    DB_HOST=$DB_HOST \
    DB_PORT=$DB_PORT \
    DB_NAME=$DB_NAME \
    DB_USER=$DB_USER \
    DB_PASSWORD=$DB_PASSWORD \
    MAILER_PASSWORD=$MAILER_PASSWORD \
    OPENSEARCH_URL=$OPENSEARCH_URL \
    OPENSEARCH_USER=$OPENSEARCH_USER \
    OPENSEARCH_PASSWORD=$OPENSEARCH_PASSWORD \
    OPENSEARCH_CA_CERT=$OPENSEARCH_CA_CERT \
    GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID \
    GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET \
    TELEGRAM_KEY=$TELEGRAM_KEY \
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
