# OmniAuth + Spotify configuration
# Uses POST-only request initiation (recommended) so provider entry points require a valid CSRF token.

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
           ENV.fetch('SPOTIFY_CLIENT_ID', ''),
           ENV.fetch('SPOTIFY_CLIENT_SECRET', ''),
           scope: 'user-read-email user-read-private user-library-read playlist-read-private user-read-recently-played',
           redirect_uri: ENV.fetch('SPOTIFY_REDIRECT_URI', '')
end


# By default OmniAuth 2 requires POST for the initial /auth/:provider request so a CSRF
# authenticity_token stored in the Rails session is submitted with the form. This is the
# secure default for production. For local dev convenience we allow GET+POST so developers
# using different hostnames (localhost vs 127.0.0.1) or tooling can debug without the
# strict POST-only restriction. Keep this change development-only.
OmniAuth.config.allowed_request_methods = %i[post]

# Allow GET+POST in development for convenience. Also allow GET when the
# OMNIAUTH_ALLOW_GET env var is set (debugging only) so we can diagnose
# POST/CSRF/session issues in production without changing the default
# secure behaviour permanently.
if Rails.env.development? || ENV['OMNIAUTH_ALLOW_GET'] == 'true'
  OmniAuth.config.allowed_request_methods = %i[get post]
  # silence the warning about allowing GET in development/debug mode
  OmniAuth.config.silence_get_warning = true if OmniAuth.config.respond_to?(:silence_get_warning=)
  Rails.logger.info "[OmniAuth] GET allowed for /auth/:provider (development or OMNIAUTH_ALLOW_GET=#{ENV['OMNIAUTH_ALLOW_GET'].inspect})"
end

# Ensure OmniAuth builds full_host dynamically from the incoming request. This avoids
# mismatches when the app is accessed via `localhost:3000` but the redirect URI/environment
# uses `127.0.0.1:3000` (or vice versa). The lambda uses the request's Host header.
OmniAuth.config.full_host = lambda do |env|
  forwarded_proto = env['HTTP_X_FORWARDED_PROTO']
  scheme = forwarded_proto || env['rack.url_scheme'] || 'http'
  host = env['HTTP_HOST'] || ENV.fetch('HOST', 'localhost:3000')
  "#{scheme}://#{host}"
end

# NOTE: These adjustments are for local development debugging only. Keep POST-only in
# production and verify redirect URIs configured in your Spotify Developer dashboard match
# the host you use in your browser.
