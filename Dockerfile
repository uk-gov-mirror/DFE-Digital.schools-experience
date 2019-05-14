############# DEPLOY IMAGE ####################

FROM ruby:2.5.5 AS deploy

ENV RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

RUN mkdir /app
WORKDIR /app

EXPOSE 3000
ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server" ]
HEALTHCHECK CMD bin/check_health.sh || exit 1

# Install Gems removing artifacts
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install --without development --jobs=$(nproc --all) && \
    rm -rf /root/.bundle/cache && \
    rm -rf /usr/local/bundle/cache

############# BUILD IMAGE #######################

FROM deploy AS build

# Install node, leaving as few artifacts as possible
RUN apt-get update && apt-get install apt-transport-https && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update && \
    apt-get install -y -o Dpkg::Options::="--force-confold" --no-install-recommends yarn nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/dpkg.log

# install NPM packages removign artifacts
COPY package.json yarn.lock ./
RUN yarn install && yarn cache clean

# Add code and compile assets
COPY . .
RUN bundle exec rake assets:precompile SECRET_KEY_BASE=stubbed SKIP_REDIS=true

# Create symlinks for CSS files without digest hashes for use in error pages
RUN bundle exec rake assets:symlink_non_digested SECRET_KEY_BASE=stubbed SKIP_REDIS=true

############# FINISH DEPLOY IMAGE ####################

FROM deploy

# Add code and compiled assets from build stage
COPY . .
COPY --from=build /app/public/assets /app/public/assets
COPY --from=build /app/public/packs /app/public/packs

# Dual purpose - symlink directories, also build the BootSnap cache
RUN bundle exec rake assets:symlink_packs SECRET_KEY_BASE=stubbed SKIP_REDIS=true
