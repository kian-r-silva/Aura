# Template Usage Examples

This file provides practical examples of using the Rails template to create applications.

## Quick Start

### Creating a New Application

```bash
# Basic usage
rails new myapp -m template.rb

# With specific database
rails new myapp -d postgresql -m template.rb

# With API-only mode
rails new myapp --api -m template.rb

# Skip some default features
rails new myapp -m template.rb --skip-action-mailer --skip-active-storage
```

### Applying to Existing Application

```bash
# Navigate to your Rails app directory
cd my-existing-app

# Apply the template
rails app:template LOCATION=/path/to/template.rb

# Or from a URL (if hosted online)
rails app:template LOCATION=https://raw.githubusercontent.com/kian-r-silva/Aura/main/template.rb
```

## Example Project Structure

After running the template, your project will have:

```
myapp/
├── app/
│   ├── models/
│   ├── controllers/
│   ├── views/
│   └── ...
├── config/
│   ├── database.yml          # PostgreSQL configuration
│   └── ...
├── features/                  # Cucumber features
│   ├── sample.feature
│   ├── step_definitions/
│   │   └── sample_steps.rb
│   └── support/
│       └── env.rb             # Database cleaner configured
├── spec/                      # RSpec tests
│   ├── controllers/
│   ├── models/
│   ├── requests/
│   ├── rails_helper.rb
│   ├── spec_helper.rb
│   └── support/
│       ├── factory_bot.rb
│       ├── shoulda_matchers.rb
│       └── capybara.rb
├── Procfile                   # Heroku process file
├── app.json                   # Heroku configuration
└── ...
```

## Real-World Example: Blog Application

### Step 1: Create the Application

```bash
rails new blog -m template.rb
cd blog
```

### Step 2: Generate a Model with RSpec

```bash
rails generate model Post title:string body:text published:boolean
rails db:migrate
```

This creates:
- Model: `app/models/post.rb`
- RSpec test: `spec/models/post_spec.rb`
- Migration: `db/migrate/xxx_create_posts.rb`

### Step 3: Write RSpec Tests

Edit `spec/models/post_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published posts' do
        published = create(:post, published: true)
        unpublished = create(:post, published: false)
        
        expect(Post.published).to include(published)
        expect(Post.published).not_to include(unpublished)
      end
    end
  end
end
```

### Step 4: Create Factory

Create `spec/factories/posts.rb`:

```ruby
FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    published { false }
    
    trait :published do
      published { true }
    end
  end
end
```

### Step 5: Update Model

Edit `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true
  
  scope :published, -> { where(published: true) }
end
```

### Step 6: Run RSpec Tests

```bash
bundle exec rspec
```

### Step 7: Write Cucumber Feature

Create `features/blog_posts.feature`:

```gherkin
Feature: Blog Posts
  As a blog visitor
  I want to view published posts
  So that I can read the blog content

  Background:
    Given the following posts exist:
      | title           | body                  | published |
      | First Post      | This is the first     | true      |
      | Draft Post      | This is a draft       | false     |
      | Second Post     | This is the second    | true      |

  Scenario: Viewing list of published posts
    When I visit the blog page
    Then I should see "First Post"
    And I should see "Second Post"
    But I should not see "Draft Post"

  Scenario: Reading a post
    When I visit the blog page
    And I click on "First Post"
    Then I should see "This is the first"
```

### Step 8: Write Step Definitions

Create `features/step_definitions/blog_steps.rb`:

```ruby
Given('the following posts exist:') do |table|
  table.hashes.each do |hash|
    Post.create!(
      title: hash['title'],
      body: hash['body'],
      published: hash['published'] == 'true'
    )
  end
end

When('I visit the blog page') do
  visit posts_path
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

When('I click on {string}') do |text|
  click_link text
end
```

### Step 9: Generate Controller and Views

```bash
rails generate controller Posts index show
```

Update routes in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  resources :posts, only: [:index, :show]
  root 'posts#index'
end
```

Update `app/controllers/posts_controller.rb`:

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.published.order(created_at: :desc)
  end

  def show
    @post = Post.find(params[:id])
  end
end
```

### Step 10: Run Cucumber Features

```bash
bundle exec cucumber
```

### Step 11: Deploy to Heroku

```bash
# Initialize git (if not already done)
git init
git add .
git commit -m "Initial blog application"

# Create Heroku app
heroku create my-blog-app

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate

# Open the app
heroku open
```

## Testing Workflow Examples

### Running Specific Tests

```bash
# Run all model specs
bundle exec rspec spec/models/

# Run specific file
bundle exec rspec spec/models/post_spec.rb

# Run specific example (by line number)
bundle exec rspec spec/models/post_spec.rb:10

# Run with documentation format
bundle exec rspec --format documentation

# Run Cucumber with specific tag
bundle exec cucumber --tags @important

# Run Cucumber scenarios matching a name
bundle exec cucumber --name "Viewing list"
```

### Test-Driven Development (TDD) Workflow

1. **Write a failing test** (Red)
   ```bash
   bundle exec rspec spec/models/post_spec.rb
   # Test fails
   ```

2. **Write minimal code to pass** (Green)
   ```ruby
   # Update model
   validates :title, presence: true
   ```
   ```bash
   bundle exec rspec spec/models/post_spec.rb
   # Test passes
   ```

3. **Refactor** (Refactor)
   ```ruby
   # Clean up code, extract methods, etc.
   ```
   ```bash
   bundle exec rspec spec/models/post_spec.rb
   # Tests still pass
   ```

### Behavior-Driven Development (BDD) Workflow

1. **Write feature** (User story)
   ```gherkin
   Feature: User login
     As a user
     I want to login
     So that I can access my account
   ```

2. **Write step definitions**
   ```ruby
   When('I login with valid credentials') do
     # Implementation
   end
   ```

3. **Implement the feature**
   ```ruby
   # Create controller, views, models
   ```

4. **Run feature**
   ```bash
   bundle exec cucumber features/user_login.feature
   ```

## Continuous Integration Example

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Setup database
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load
      
      - name: Run RSpec
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: bundle exec rspec
      
      - name: Run Cucumber
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: bundle exec cucumber
```

## Additional Tips

### Using Factory Bot in Rails Console

```bash
rails console

# Create a post
post = FactoryBot.create(:post)

# Create multiple posts
posts = FactoryBot.create_list(:post, 5)

# Create a published post
published_post = FactoryBot.create(:post, :published)

# Build without saving
post = FactoryBot.build(:post)
```

### Using Database Cleaner

The template configures Database Cleaner automatically. For custom strategies:

```ruby
# In spec/support/database_cleaner.rb
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

### Debugging Tests

```ruby
# Add to Gemfile in development, test group
gem 'pry-rails'
gem 'pry-byebug'

# In your test
it 'does something' do
  binding.pry  # Debugger will stop here
  expect(something).to eq(true)
end
```

## Resources

- Template file: `template.rb`
- Template guide: `TEMPLATE_GUIDE.md`
- Rails guides: https://guides.rubyonrails.org/
- RSpec Rails: https://github.com/rspec/rspec-rails
- Cucumber Rails: https://github.com/cucumber/cucumber-rails
