# Rails Application Template
# Includes: Cucumber for BDD stories, RSpec for testing, and Heroku deployment configuration
#
# Usage: rails new myapp -m template.rb

# Add gems to Gemfile
gem_group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'capybara'
  gem 'selenium-webdriver'
end

gem_group :test do
  gem 'shoulda-matchers', '~> 5.0'
  gem 'webdrivers'
end

gem_group :development do
  gem 'annotate'
end

# Heroku-specific gems
gem 'pg', '~> 1.5'

# Run bundle install
after_bundle do
  # Generate RSpec configuration
  generate 'rspec:install'
  
  # Generate Cucumber configuration
  generate 'cucumber:install'
  
  # Configure database_cleaner for Cucumber
  inject_into_file 'features/support/env.rb', after: "require 'cucumber/rails'\n" do <<-'RUBY'

# Configure database cleaner
require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end
RUBY
  end
  
  # Create spec/support directory and configure RSpec
  run 'mkdir -p spec/support'
  
  # Configure RSpec to load support files
  inject_into_file 'spec/rails_helper.rb', after: "# Add additional requires below this line. Rails is not loaded until this point!\n" do <<-'RUBY'

# Require support files
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
RUBY
  end
  
  # Configure shoulda-matchers
  create_file 'spec/support/shoulda_matchers.rb' do <<-'RUBY'
require 'shoulda-matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
RUBY
  end
  
  # Configure FactoryBot
  create_file 'spec/support/factory_bot.rb' do <<-'RUBY'
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
RUBY
  end
  
  # Configure Capybara
  create_file 'spec/support/capybara.rb' do <<-'RUBY'
require 'capybara/rails'
require 'capybara/rspec'

Capybara.default_driver = :selenium
Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  config.include Capybara::DSL
end
RUBY
  end
  
  # Create Procfile for Heroku
  create_file 'Procfile' do <<-'PROCFILE'
web: bundle exec puma -C config/puma.rb
PROCFILE
  end
  
  # Create app.json for Heroku
  create_file 'app.json' do <<-'JSON'
{
  "name": "Aura Application",
  "description": "Ruby on Rails application with Cucumber and RSpec",
  "repository": "https://github.com/kian-r-silva/Aura",
  "keywords": ["ruby", "rails", "cucumber", "rspec"],
  "addons": [
    "heroku-postgresql"
  ],
  "env": {
    "RAILS_ENV": {
      "description": "Rails environment",
      "value": "production"
    },
    "RACK_ENV": {
      "description": "Rack environment",
      "value": "production"
    },
    "SECRET_KEY_BASE": {
      "description": "Secret key for verifying the integrity of signed cookies",
      "generator": "secret"
    }
  },
  "formation": {
    "web": {
      "quantity": 1,
      "size": "basic"
    }
  },
  "buildpacks": [
    {
      "url": "heroku/ruby"
    }
  ]
}
JSON
  end
  
  # Update database.yml for PostgreSQL (Heroku uses PostgreSQL)
  remove_file 'config/database.yml'
  create_file 'config/database.yml' do <<-'YAML'
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: <%= app_name %>_development

test:
  <<: *default
  database: <%= app_name %>_test

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
YAML
  end
  
  # Create a sample feature file
  create_file 'features/sample.feature' do <<-'FEATURE'
Feature: Sample Feature
  As a user
  I want to see a sample feature
  So that I can understand how Cucumber works

  Scenario: Visit homepage
    Given I am on the homepage
    When I look at the page
    Then I should see the application
FEATURE
  end
  
  # Create step definitions for the sample feature
  create_file 'features/step_definitions/sample_steps.rb' do <<-'RUBY'
Given('I am on the homepage') do
  visit root_path
end

When('I look at the page') do
  # Intentionally left blank - we're just viewing the page
end

Then('I should see the application') do
  expect(page).to have_http_status(:success)
end
RUBY
  end
  
  # Create a sample RSpec model test
  create_file 'spec/models/.gitkeep' do
    ""
  end
  
  # Create sample controller spec
  create_file 'spec/controllers/.gitkeep' do
    ""
  end
  
  # Create sample request spec
  create_file 'spec/requests/.gitkeep' do
    ""
  end
  
  # Create README with instructions
  append_to_file 'README.md' do <<-'README'

## Testing

This application is configured with:

### RSpec
- Unit and integration testing framework
- Run tests: `bundle exec rspec`
- Generate a new spec: `rails generate rspec:model ModelName`

### Cucumber
- Behavior-driven development (BDD) testing framework
- Run features: `bundle exec cucumber`
- Features are located in the `features/` directory

### Test Coverage
The following gems are included for comprehensive testing:
- **rspec-rails**: RSpec testing framework
- **cucumber-rails**: Cucumber BDD framework
- **factory_bot_rails**: Test data generation
- **faker**: Fake data generation
- **capybara**: Integration testing
- **selenium-webdriver**: Browser automation
- **database_cleaner**: Database cleaning between tests
- **shoulda-matchers**: RSpec matchers for common Rails functionality

## Heroku Deployment

This application is configured for Heroku deployment:

### Setup
1. Install Heroku CLI: https://devcenter.heroku.com/articles/heroku-cli
2. Login to Heroku: `heroku login`
3. Create a Heroku app: `heroku create your-app-name`
4. Add PostgreSQL addon: `heroku addons:create heroku-postgresql:mini`

### Deploy
1. Commit your changes: `git commit -am "Ready for deployment"`
2. Push to Heroku: `git push heroku main`
3. Run migrations: `heroku run rails db:migrate`
4. Open your app: `heroku open`

### Configuration
- Procfile: Defines the web process
- app.json: Heroku app configuration and addons
- database.yml: Configured for PostgreSQL with DATABASE_URL

### Environment Variables
Set environment variables on Heroku:
```bash
heroku config:set VARIABLE_NAME=value
```

The SECRET_KEY_BASE is automatically generated by Heroku.
README
  end
  
  # Initialize git repository (if not already initialized)
  git :init unless File.exist?('.git')
  
  # Create .gitignore additions for test artifacts
  append_to_file '.gitignore' do <<-'GITIGNORE'

# Test coverage
/coverage/

# RSpec
/spec/examples.txt

# Cucumber
rerun.txt

# Environment variables
.env
.env.local
GITIGNORE
  end
  
  say "=" * 80
  say "Rails application template applied successfully!"
  say "=" * 80
  say ""
  say "Your application now includes:"
  say "  ✓ RSpec for unit and integration testing"
  say "  ✓ Cucumber for BDD stories and features"
  say "  ✓ Heroku deployment configuration"
  say "  ✓ PostgreSQL database configuration"
  say "  ✓ Factory Bot, Faker, Capybara, and Selenium for testing"
  say ""
  say "Next steps:"
  say "  1. Create the database: rails db:create"
  say "  2. Run migrations: rails db:migrate"
  say "  3. Run RSpec tests: bundle exec rspec"
  say "  4. Run Cucumber features: bundle exec cucumber"
  say "  5. Deploy to Heroku: git push heroku main"
  say ""
  say "=" * 80
end
