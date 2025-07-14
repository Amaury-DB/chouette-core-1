FROM ruby:2.7

RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    build-essential \
    libpq-dev \
    libxml2-dev \
    zlib1g-dev \
    libmagic-dev \
    libmagickwand-dev \
    libproj-dev \
    libgeos-dev \
    libcurl4-openssl-dev \
    python3

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

RUN npm install -g yarn

RUN gem update --system 3.3.26
RUN gem install bundler:2.4.22

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle _2.4.22_ install --jobs 1 --retry 3

COPY . .

RUN yarn install

ENV NODE_OPTIONS=--openssl-legacy-provider
RUN bundle exec rake assets:precompile

EXPOSE 3000

ENV RAILS_ENV=production

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]