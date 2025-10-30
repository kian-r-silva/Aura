c
Team
- Kian Silva (UNI: krs2205)
- Ben Sidley (UNI:bms2227)
- Joao Pedro Hall Lima (UNI: jh4645)
- Nick Felix (UNI: nf2573)



# Homebrew packages (Postgres + optional Ruby toolchain)
brew update
brew install postgresql
# Start Postgres service
brew services start postgresql
# Ensure your shell has a Ruby manager if needed (rbenv/rvm) and correct Ruby installed
 e.g. with rbenv:
 brew install rbenv
 rbenv install 3.4.7
 rbenv local 3.4.7
3. Install Ruby gems
gem install bundler # if needed
bundle install


run to create env template:
(copy from below here)
cat > .env.local <<'EOF'
# Local development environment variables for Aura
RAILS_ENV=development
PORT=3000

# Database (leave DB_HOST unset to use local Postgres socket; only set if you need TCP)
# DB_HOST=localhost
# DB_USER=dev
# DB_PASSWORD=pass
# DATABASE_URL=postgres://dev:pass@localhost:5432/aura_development

# Spotify OAuth
SPOTIFY_CLIENT_ID=6bd70b8c95bf45df8c3dd9a4e3815f55
SPOTIFY_CLIENT_SECRET=303a74e8a1ad40e7be3dc010e0cd0be4
SPOTIFY_REDIRECT_URI=http://localhost:3000/auth/spotify/callback
EOF
(END COPY)

run:
echo ".env.local" >> .gitignore


5. Load local environment variables into your shell (so echo shows them and they are available to any child process)
# from project root
set -a 
source .local.env
set +a

# verify
echo "$SPOTIFY_CLIENT_ID"
echo "$SPOTIFY_REDIRECT_URI"

5. Ensure Postgres can create DBs/users (one-time)
# create a superuser for the current macOs user if it doesn't exist
createuser -s $(whoami) 2>/dev/null || true
local.env at Rails boot via the initializer, but exporting in your shell is useful for running CLI checks and starting the
6. Create / migrate / seed the database
# stop Spring so Rails picks up any env/initializer changes
bin/spring stop
# create DBs, run migrations, load seeds
bin/rails db:create 
bin/rails db:migrate
bin/rails db:seed # only if you have seeds and want them applied
7. Set SECRET_KEY_BASE for dev (optional but useful)
export SECRET_KEY_BASE=$(bin/rails secret)
# or add to .local.env: SECRET_KEY_BASE=the_value

# run inside Rails process (safe to paste presence/length but not secrets)
bin/rails runner 'puts "SPOTIFY_CLIENT_ID present? #{ENVI\"SPOTIFY_CLIENT_ID\"] present?}"; puts "SPOTIFY_CLIENT_SECRET
9. Confirm the redirect URI is registered in Spotify Developer Dashboard
• In Spotify dev console for your app, ensure an exact match (protocol + host + port + path).
• Example: http://127.0.0.1:3000/auth/spotify/callback
• Important: use the same host in your browser as the redirect URI (127.0.0.1 vs localhost differences matter).
10. Start the Rails server
bin/spring stop # ensure fresh boot 
bin/rails server -p 3000
11. Watch logs while exercising the app (recommended)
tail -f log/development.log

