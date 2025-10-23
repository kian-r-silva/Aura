# Rails Template Guide

This guide explains the features and configuration provided by the `template.rb` Rails application template.

## Overview

The template automatically sets up a complete testing and deployment environment for Ruby on Rails applications with:
- **RSpec** for unit and integration testing
- **Cucumber** for Behavior-Driven Development (BDD)
- **Heroku** deployment configuration with PostgreSQL

## Gems Added

### Testing Gems (Development & Test)

| Gem | Purpose |
|-----|---------|
| `rspec-rails` | RSpec testing framework for Rails |
| `cucumber-rails` | Cucumber BDD framework for Rails |
| `database_cleaner` | Ensures clean database state between tests |
| `factory_bot_rails` | Fixtures replacement for creating test data |
| `faker` | Generates fake data for tests |
| `capybara` | Integration testing tool for web applications |
| `selenium-webdriver` | Browser automation for feature tests |

### Testing Gems (Test Only)

| Gem | Purpose |
|-----|---------|
| `shoulda-matchers` | RSpec matchers for common Rails functionality |
| `webdrivers` | Automatic management of browser drivers |

### Development Gems

| Gem | Purpose |
|-----|---------|
| `annotate` | Adds schema information to models |

### Production Gems

| Gem | Purpose |
|-----|---------|
| `pg` | PostgreSQL adapter (required for Heroku) |

## Files Created

### Testing Configuration

- `spec/` - RSpec test directory
  - `spec/rails_helper.rb` - RSpec Rails configuration
  - `spec/spec_helper.rb` - RSpec general configuration
  - `spec/support/` - Support files directory
    - `spec/support/shoulda_matchers.rb` - Shoulda matchers configuration
    - `spec/support/factory_bot.rb` - Factory Bot configuration
    - `spec/support/capybara.rb` - Capybara configuration

- `features/` - Cucumber features directory
  - `features/support/env.rb` - Cucumber environment configuration
  - `features/sample.feature` - Example feature file
  - `features/step_definitions/sample_steps.rb` - Example step definitions

### Heroku Configuration

- `Procfile` - Defines processes to run on Heroku
- `app.json` - Heroku app manifest with addons and configuration
- `config/database.yml` - PostgreSQL database configuration

## Testing Workflows

### Running RSpec Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests matching a pattern
bundle exec rspec spec/models/

# Run with documentation format
bundle exec rspec --format documentation
```

### Running Cucumber Features

```bash
# Run all features
bundle exec cucumber

# Run specific feature
bundle exec cucumber features/sample.feature

# Run features with specific tag
bundle exec cucumber --tags @wip

# Run with verbose output
bundle exec cucumber --verbose
```

### Writing Tests

#### RSpec Example

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end

  describe 'associations' do
    it { should have_many(:posts) }
  end

  describe '#full_name' do
    it 'returns the full name' do
      user = create(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end
end
```

#### Cucumber Example

```gherkin
# features/user_registration.feature
Feature: User Registration
  As a visitor
  I want to register for an account
  So that I can access the application

  Scenario: Successful registration
    Given I am on the registration page
    When I fill in "Email" with "user@example.com"
    And I fill in "Password" with "password123"
    And I click "Sign Up"
    Then I should see "Welcome to the application"
    And I should be on the dashboard page
```

```ruby
# features/step_definitions/user_steps.rb
Given('I am on the registration page') do
  visit new_user_registration_path
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I click {string}') do |button|
  click_button button
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should be on the dashboard page') do
  expect(current_path).to eq(dashboard_path)
end
```

## Heroku Deployment

### Initial Setup

1. **Install Heroku CLI**
   ```bash
   # macOS
   brew tap heroku/brew && brew install heroku
   
   # Ubuntu
   curl https://cli-assets.heroku.com/install.sh | sh
   ```

2. **Login to Heroku**
   ```bash
   heroku login
   ```

3. **Create Heroku App**
   ```bash
   heroku create your-app-name
   ```

4. **Add PostgreSQL**
   ```bash
   # Automatically added via app.json when using Heroku Button
   # Or manually add:
   heroku addons:create heroku-postgresql:mini
   ```

### Deployment Process

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "Ready for deployment"
   ```

2. **Push to Heroku**
   ```bash
   git push heroku main
   ```

3. **Run database migrations**
   ```bash
   heroku run rails db:migrate
   ```

4. **Seed database (if needed)**
   ```bash
   heroku run rails db:seed
   ```

5. **Open your application**
   ```bash
   heroku open
   ```

### Managing Environment Variables

```bash
# Set a variable
heroku config:set VARIABLE_NAME=value

# View all variables
heroku config

# View specific variable
heroku config:get VARIABLE_NAME

# Remove a variable
heroku config:unset VARIABLE_NAME
```

### Viewing Logs

```bash
# View recent logs
heroku logs

# View logs in real-time
heroku logs --tail

# View logs for specific process
heroku logs --ps web
```

### Running Console

```bash
# Open Rails console
heroku run rails console

# Run one-off command
heroku run rails runner "puts User.count"
```

## Database Configuration

The template configures PostgreSQL for all environments:

```yaml
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: myapp_development

test:
  <<: *default
  database: myapp_test

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
```

### Local PostgreSQL Setup

**macOS (with Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Ubuntu:**
```bash
sudo apt-get install postgresql postgresql-contrib
sudo service postgresql start
```

**Creating Development Database:**
```bash
rails db:create
rails db:migrate
```

## Customizing the Template

You can modify `template.rb` to add additional gems or configuration:

### Adding More Gems

```ruby
# Add to appropriate gem_group block
gem_group :development, :test do
  gem 'pry-rails'  # Better console
  gem 'rubocop-rails'  # Code linter
end
```

### Adding Custom Configuration

```ruby
after_bundle do
  # Your custom configuration here
  create_file 'config/initializers/custom.rb' do
    "# Custom configuration"
  end
end
```

## Troubleshooting

### Common Issues

**PostgreSQL not installed:**
```
Error: Could not find a valid PostgreSQL database
```
Solution: Install PostgreSQL locally (see Database Configuration section)

**Webdrivers error:**
```
Error: Unable to find chromedriver
```
Solution: Install Chrome browser or use different Capybara driver

**Heroku deployment fails:**
```
Error: Failed to install gems via Bundler
```
Solution: Ensure `Gemfile.lock` is committed and bundle install succeeds locally

## Additional Resources

- [RSpec Documentation](https://rspec.info/)
- [Cucumber Documentation](https://cucumber.io/docs/cucumber/)
- [Heroku Rails Guide](https://devcenter.heroku.com/articles/getting-started-with-rails7)
- [Factory Bot Documentation](https://github.com/thoughtbot/factory_bot)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
