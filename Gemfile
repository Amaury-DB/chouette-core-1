source 'https://rubygems.org'

# Use https for github
git_source(:github) { |name| "https://github.com/#{name}.git" }
git_source(:en_route) { |name| "https://bitbucket.org/enroute-mobi/#{name}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4', '>= 5.2.4.6'

# Use SCSS for stylesheets
gem 'sassc-rails', '>= 2.1.2'
gem 'sassc', '2.1.0'
gem 'sass'

group :production do
  gem 'mini_racer'
end

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7.2'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '>= 5.0.0'

gem 'sprockets', '~> 3.7.2'

# Webpacker
gem 'webpacker', '~> 5.2', '>= 5.2.1'

# Use jquery as the JavaScript library
gem 'jquery-rails', '>= 4.4.0'
gem 'jquery-ui-rails', '>= 6.0.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# Select2 for pretty select boxes w. autocomplete
gem 'select2-rails', '~> 4.0', '>= 4.0.3'

# ActiveRecord associations on top of PostgreSQL arrays
gem 'has_array_of', en_route: 'has_array_of'

gem 'rails-observers'
# gem 'wisper', '2.0.0'

# Use SeedBank for spliting seeds
gem 'seedbank', '0.4.0'

gem 'faraday_middleware'
gem 'faraday'

gem 'pg'

gem 'activerecord-postgis-adapter'
gem 'postgres-copy', '>= 1.5.0'

gem 'polylines'
gem 'bulk_insert'

gem 'graphql'

# Codifligne API
gem 'codifligne', en_route: 'ilico-api'
# ICar API
gem 'icar', en_route: 'icar-api'

# Authentication
gem 'devise', '>= 4.7.3'
gem 'devise_cas_authenticatable', '>= 1.10.4'
gem 'devise-encryptable', '>= 0.2.0'
gem 'devise_invitable', '>= 2.0.3'

# Authorization
gem 'pundit'

# Map, Geolocalization
gem 'map_layers', '0.0.4'
gem 'rgeo'
gem 'rgeo-proj4', en_route: 'rgeo-proj4'
# gem 'georuby-ext'
gem 'geokit'
gem 'georuby', '2.3.0' # Fix version for georuby-ext because api has changed
gem 'ffi-geos'

gem 'ffi'
gem 'mimemagic'

# User interface
gem 'language_engine', '0.0.9', en_route: 'language_engine'
gem 'calendar_helper', '0.2.5'
gem 'cocoon'
gem 'slim-rails', '>= 3.2.0'
gem 'formtastic', '>= 3.1.5'
gem 'simple_form', '>= 5.0.3'
gem 'will_paginate-bootstrap'
gem 'gretel', '>= 4.2.0'
gem 'country_select'
gem 'flag-icons-rails', '>= 3.4.6.1'
gem 'i18n-js'
gem 'clockpicker-rails', '>= 0.0.2'
gem 'font_awesome5_rails'

# Format Output
gem 'json'
gem 'rubyzip'
gem 'roo', '>= 2.8.3'

# Controller
gem 'inherited_resources', '>= 1.11.0'
gem 'responders', '>= 3.0.1'

# Model
gem 'will_paginate'
gem 'ransack'
gem 'active_attr', '>= 0.15.0'

gem 'draper', '>= 4.0.1'

gem 'enumerize'
gem 'deep_cloneable'
gem 'acts-as-taggable-on'
gem 'nokogiri', '>= 1.11.0'

gem 'acts_as_list'
gem 'acts_as_tree'

gem 'rabl'
gem 'carrierwave', '>= 1.3.2'
gem 'carrierwave-google-storage', github: 'metaware/carrierwave-google-storage'
gem 'rmagick'

gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'delayed_job_heartbeat_plugin'

gem 'whenever', en_route: 'whenever', require: false
gem 'rake'
gem 'apartment'
gem 'aasm'
gem 'puma', '>= 5.3.1'
gem 'postgresql_cursor'

# Cache
gem 'redis-rails', '>= 5.0.2'

gem 'gtfs', en_route: 'gtfs'
gem 'netex', en_route: 'netex'
gem 'rgeo-shapefile'

gem 'ddtrace'

# Monitoring
gem 'sentry-raven'

group :development do
  gem 'rails-erd'
  gem 'license_finder'
  gem 'bundler-audit'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'derailed_benchmarks'

  gem 'bummr'
  gem 'graphiql-rails', '>= 1.7.0'

  gem 'guard-rspec', require: false
end

group :test do
  gem 'email_spec'
  gem 'htmlbeautifier'
  gem 'timecop'
  gem 'rspec-snapshot'
  gem 'rails-controller-testing', '>= 1.0.5'
  gem 'fuubar'
  gem 'rspec-benchmark'
  gem 'pundit-matchers', '>= 1.6.0'

  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
end

group :test, :development do
  gem 'rspec-rails', '>= 3.5.2'
  gem 'capybara', '~> 3.15.1'
  gem 'database_cleaner'
  gem 'poltergeist', '>= 1.18.1'
  gem 'stackprof'

  gem 'webmock'
  gem 'shoulda-matchers'

  gem 'parallel_tests'

  gem 'letter_opener'
  gem 'letter_opener_web', '~> 1.4', '>= 1.4.0'

  gem 'ffaker', '~> 2.1.0'
  gem 'faker'

  gem 'factory_bot_rails', '>= 6.1.0'

  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry-byebug'

  gem 'teaspoon-jasmine', '>= 2.3.4'
  gem 'phantomjs'
end

# I18n
gem 'rails-i18n', '>= 5.1.3'
gem 'devise-i18n', '>= 1.9.2'
gem 'i18n-tasks', '>= 0.9.31'

# Rails Assets
source 'https://rails-assets.org' do
  gem 'rails-assets-footable', '~> 2.0.3'

  # Use twitter bootstrap resources
  gem 'rails-assets-bootstrap-sass-official', '~> 3.3.0'
  gem 'rails-assets-respond'
  gem 'rails-assets-jquery-tokeninput', '~> 1.7.0'
end

gem 'activerecord-nulldb-adapter', require: (ENV['RAILS_DB_ADAPTER'] == 'nulldb')

gem 'google-cloud-storage', '> 1.4.0'
gem 'net-sftp'
