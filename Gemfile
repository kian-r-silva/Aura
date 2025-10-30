source "https://rubygems.org"

# Ruby version
ruby "3.4.7"

# Rails & core
gem "rails", "~> 8.1.0"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bcrypt", "~> 3.1.18"
gem "image_processing", "~> 1.2"
gem "bootsnap", require: false

# Production DB (Heroku)
gem "pg", "~> 1.5"

# Spotify / HTTP
gem "omniauth-spotify"
gem "faraday", "~> 2.7"

# Basecamp/optional
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "kamal", require: false
gem "thruster", require: false

# Windows/JRuby time zone data
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # Dev/test DB (keep sqlite OUT of production)
  gem "sqlite3", ">= 2.1"

  # Tooling
  gem "rspec-rails", "~> 6.0"
  gem "cucumber-rails", require: false
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "faker"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "erb_lint", require: false

  # Debugging / security
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "annotate"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "shoulda-matchers", "~> 5.0"
  gem "simplecov", require: false
end

