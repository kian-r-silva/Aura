# Aura
Engineering Software-as-a-Service Project

## Rails Application Template

This repository contains a comprehensive Ruby on Rails application template that includes:

- **Cucumber** for Behavior-Driven Development (BDD) stories
- **RSpec** for unit and integration testing
- **Heroku** deployment configuration

### Usage

To create a new Rails application using this template:

```bash
rails new myapp -m template.rb
```

Or apply the template to an existing Rails application:

```bash
rails app:template LOCATION=template.rb
```

### What's Included

#### Testing Frameworks

**RSpec**
- Full RSpec configuration with support files
- Shoulda Matchers for common Rails testing patterns
- Factory Bot for test data generation
- Faker for generating fake data
- Capybara and Selenium for integration testing

**Cucumber**
- Cucumber-Rails configuration for BDD
- Database Cleaner for test isolation
- Sample feature file and step definitions
- Capybara integration for feature testing

#### Heroku Configuration

**Deployment Files**
- `Procfile`: Defines the web process for Heroku
- `app.json`: Heroku app configuration with PostgreSQL addon
- `database.yml`: Configured for PostgreSQL (Heroku's database)

**Database**
- PostgreSQL gem included (required by Heroku)
- Database configuration for development, test, and production environments
- Automatic DATABASE_URL support for Heroku

### Getting Started

After creating your application with the template:

1. **Create the database:**
   ```bash
   rails db:create
   ```

2. **Run migrations:**
   ```bash
   rails db:migrate
   ```

3. **Run RSpec tests:**
   ```bash
   bundle exec rspec
   ```

4. **Run Cucumber features:**
   ```bash
   bundle exec cucumber
   ```

5. **Deploy to Heroku:**
   ```bash
   heroku create your-app-name
   heroku addons:create heroku-postgresql:mini
   git push heroku main
   heroku run rails db:migrate
   ```

### Template Features

- Automatic installation of all required gems
- Pre-configured RSpec with support files
- Pre-configured Cucumber with sample feature
- Database Cleaner setup for both RSpec and Cucumber
- Factory Bot and Faker integration
- Capybara and Selenium WebDriver for browser testing
- Shoulda Matchers for cleaner test syntax
- PostgreSQL configuration for Heroku compatibility
- Procfile for Heroku deployment
- app.json with Heroku addons and environment variables
- Updated .gitignore for test artifacts

### Requirements

- Ruby 3.0 or higher
- Rails 7.0 or higher
- PostgreSQL installed locally for development

### Contributing

This template is designed to be a starting point for Rails applications with comprehensive testing and easy Heroku deployment. Feel free to customize it for your specific needs.
