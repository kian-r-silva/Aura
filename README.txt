
Team
- Kian Silva (UNI: krs2205)
- Ben Sidley (UNI: bms2227)
- Joao Pedro Hall Lima (UNI: jh4645)
- Nick Felix (UNI: nf2573)

Application URL (deployed):
- https://aura-engineering-saas-279c3bd96a5a.herokuapp.com/

Prerequisites (macOS)
---------------------
- Homebrew (https://brew.sh/)
- PostgreSQL (installed via Homebrew or otherwise)
- rbenv (recommended) or another Ruby manager (rvm, asdf)
- Ruby 3.4.7 (the project was developed on this version)

Quick setup
------------------------
Open a terminal and run these commands (they're annotated below):

```bash
# 1) Install system packages (Homebrew already installed)
brew update
brew install postgresql rbenv

# start Postgres (Homebrew service)
brew services start postgresql

# 2) Install Ruby via rbenv (if not using another manager)
rbenv install 3.4.7
rbenv local 3.4.7

# 3) Install bundler and project gems
gem install bundler
bundle install
```

Environment variables
---------------------
Create a local environment file at the project root named `.env.local` (this file is ignored by git).
You can create it with the following contents (fill any values marked <...>):

```bash
cat > .env.local <<'EOF'
# Local environment variables
RAILS_ENV=development
PORT=3000

# Last.fm
# Obtain these from the comments of the submission.
LASTFM_API_KEY=<your_lastfm_api_key>
LASTFM_SHARED_SECRET=<your_lastfm_shared_secret>
LASTFM_CALLBACK_URL=http://localhost:3000/lastfm_auth/callback

# Optional: SECRET_KEY_BASE for local dev (otherwise Rails will generate one)
SECRET_KEY_BASE=<optional_secret_key>

EOF

echo ".env.local" >> .gitignore || true

# Load variables into current shell (or set in your terminal profile)
set -a; source .env.local; set +a
```

Database setup
--------------
Run these commands from the project root. They create the database, run the migrations, and (optionally) seed the data.

```bash
# One-time on a fresh machine: create a Postgres superuser for your macOS user
createuser -s "$(whoami)" 2>/dev/null || true

# Create and migrate development DB
bin/rails db:create db:migrate

# Optional: seed data (if seeds.rb present)
bin/rails db:seed
```

Test database
-------------
Ensure the test database schema is present before running specs. Run either:

```bash
bin/rails db:migrate RAILS_ENV=test
# or (preferred when starting fresh):
bin/rails db:schema:load RAILS_ENV=test
```

Running the app locally
-----------------------
Start the Rails server on port 3000:

```bash
bin/rails server -p 3000
```

Open http://localhost:3000 in your browser.


Running tests (RSpec + Cucumber)
--------------------------------
We provide a rake task that runs RSpec then Cucumber under SimpleCov and merges coverage results into a single HTML report.

1) Run the RSpec suite only:

```bash
bundle exec rspec
```

2) Run the Cucumber features only:

```bash
bundle exec cucumber
```

3) Generate the combined SimpleCov report:

```bash
bundle exec rake coverage:all
```

After `rake coverage:all` completes, open `coverage/index.html` in a browser to view the combined coverage report.

Notes about Last.fm integration
-------------------------------
- Last.fm integration is optional for core testing, but several features (recommendations, recent tracks) rely on it. If you want to exercise those flows, set the `LASTFM_API_KEY` and `LASTFM_SHARED_SECRET` in `.env.local`.
- The app has a `LastfmAuthController` that handles the OAuth-like flow; `lastfm_auth_path` in the app will redirect to Last.fm to authorize and then return to the callback to save session data to the user.

Common commands reference
-------------------------
- Start server: `bin/rails server -p 3000`
- Run RSpec: `bundle exec rspec`
- Run Cucumber: `bundle exec cucumber`
- Generate merged coverage: `bundle exec rake coverage:all`
- Load test schema: `bin/rails db:schema:load RAILS_ENV=test`
