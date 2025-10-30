
Team
- Kian Silva (UNI: krs2205)
- Ben Sidley (UNI:bms2227)
- Joao Pedro Hall Lima (UNI: jh4645)
- Nick Felix (UNI: nf2573)

This page is hosted on Heroku at:  https://aura-engineering-saas-279c3bd96a5a.herokuapp.com/

## Local setup

```bash
# 1. Homebrew packages (Postgres + optional Ruby toolchain)
brew update
brew install postgresql
brew services start postgresql

# 2. Ruby (using rbenv example)
brew install rbenv
rbenv install 3.4.7
rbenv local 3.4.7

# 3. Install Ruby gems
gem install bundler   # if needed
bundle install


Environment file
Run this once to create a local environment template:
(copy from below)

cat > .env.local <<'EOF'
# Local development environment variables for Aura
RAILS_ENV=development
PORT=3000

# Database (leave DB_HOST unset to use local Postgres socket)
# DB_HOST=localhost
# DB_USER=dev
# DB_PASSWORD=pass

# Spotify OAuth
extract from repo secrets
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=
SPOTIFY_REDIRECT_URI=http://localhost:3000/auth/spotify/callback
EOF

(end copy)

# Ensure it isn’t committed
echo ".env.local" >> .gitignore
Load environment variables
# From project root
set -a
source .env.local
set +a

# Verify
echo "$SPOTIFY_CLIENT_ID"
echo "$SPOTIFY_REDIRECT_URI"
Database setup
# One-time: create a Postgres superuser for your macOS user
createuser -s "$(whoami)" 2>/dev/null || true

# Create, migrate, (optionally) seed
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed   # if you have seeds
Optional: secret key for development
export SECRET_KEY_BASE=$(bin/rails secret)
# or add to .env.local: SECRET_KEY_BASE=<the_value>
Verify Spotify variables in Rails
bin/rails runner 'puts "SPOTIFY_CLIENT_ID present? #{ENV.key?("SPOTIFY_CLIENT_ID")}"'
Spotify redirect URI check
In the Spotify Developer Dashboard, ensure your redirect URI matches exactly:
http://127.0.0.1:3000/auth/spotify/callback
Protocol, host, and port must match what you use locally.
Start the Rails server
bin/rails server -p 3000
Visit http://localhost:3000
Watch logs (optional)
tail -f log/development.log
Run tests & user stories
bundle exec rspec
bundle exec cucumber
