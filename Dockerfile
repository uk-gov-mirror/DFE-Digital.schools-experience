FROM ruby:2.5

ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

RUN mkdir /app
WORKDIR /app

EXPOSE 3000
ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "Puma" ]
HEALTHCHECK CMD curl --fail http://localhost:3000/ || exit 1

COPY .ruby-version Gemfile Gemfile.lock ./
#RUN bundle install --without development && rm -rf /root/.bundle/cache && rm -rf /usr/local/bundle/cache

RUN bundle install --without development --jobs=$(nproc --all)

COPY . .
# RUN bundle exec rake assets:precompile
