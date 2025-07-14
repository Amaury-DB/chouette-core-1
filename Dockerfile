FROM ruby:2.7

# Install system dependencies
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

# Install Node.js 18.x (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install Yarn 1.x (latest stable)
RUN npm install -g yarn

# Upgrade RubyGems and install correct Bundler version
RUN gem update --system 3.3.26
RUN gem install bundler:2.4.22

WORKDIR /app

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle _2.4.22_ install --retry 3

# Copy the rest of the application code
COPY . .

# Install JS dependencies
RUN yarn install

# Precompile Rails assets
RUN bundle exec rake assets:precompile

EXPOSE 3000

ENV RAILS_ENV=production

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
