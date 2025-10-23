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
