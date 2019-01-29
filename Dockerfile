FROM ruby:2.5-alpine

ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

RUN mkdir /app
WORKDIR /app

EXPOSE 3000
ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server" ]
HEALTHCHECK CMD curl --fail http://localhost:3000/ || exit 1

# Install node, leaving as few artifacts as possible
RUN apk add --update --no-cache git gcc libxml2 bash build-base libpq postgresql-dev tzdata nodejs yarn

# Install Gems removing artifacts
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install --without development --jobs=1 && \
    rm -rf /root/.bundle/cache && \
    rm -rf /usr/local/bundle/cache

## Add code and compile assets
COPY . .
RUN yarn install && \
    yarn cache clean && \
    bundle exec rake assets:precompile SECRET_KEY_BASE=stubbed && \
    rm -rf node_modules
