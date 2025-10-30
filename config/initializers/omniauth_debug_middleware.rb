# Development-only middleware to log incoming requests to the OmniAuth endpoints
if Rails.env.development? || ENV['OMNIAUTH_DEBUG'] == 'true'
  # Lightweight debug middleware to inspect incoming requests to OmniAuth endpoints.
  # Enabled in development by default, but can also be turned on in production by
  # setting OMNIAUTH_DEBUG=true in the environment (use briefly and avoid
  # logging secrets in long-term logs).
  class OmniAuthDebugMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      if req.path.start_with?('/auth/spotify')
        Rails.logger.debug "[OmniAuthDebug] Incoming #{req.request_method} #{req.path}"
        # log host, cookies, and a summary of params (avoid dumping secrets)
        Rails.logger.debug "[OmniAuthDebug] Host: #{req.host}:#{req.port} ; full_host: #{req.scheme}://#{req.host}:#{req.port}"
  # Avoid dumping full cookie values into logs long-term. Log whether the
  # session cookie is present and the cookie header length instead.
  cookie_header = env['HTTP_COOKIE']
  Rails.logger.debug "[OmniAuthDebug] Cookie header present? #{cookie_header.present?} ; contains _aura_session? #{cookie_header&.include?('_aura_session')} ; length=#{cookie_header&.length || 0}"
        begin
          # parse params (works for GET and POST). Use rescue to avoid raising for multipart/large bodies
          params = req.params rescue {}
        rescue StandardError => e
          params = { parse_error: e.message }
        end
        Rails.logger.debug "[OmniAuthDebug] QUERY_STRING: #{env['QUERY_STRING'].inspect}"
        Rails.logger.debug "[OmniAuthDebug] Params keys: #{params.keys.inspect}"
        # Inspect session token if present and show omniauth.state value
        sess = env['rack.session'] rescue nil
        Rails.logger.debug "[OmniAuthDebug] session keys: #{sess&.keys.inspect}"
        Rails.logger.debug "[OmniAuthDebug] session contains omniauth.state? #{sess && sess.key?('omniauth.state')}"
        Rails.logger.debug "[OmniAuthDebug] session has _csrf_token? #{sess && sess['_csrf_token'].present?}"
      end

      @app.call(env)
    end
  end

  # Insert before OmniAuth so we can inspect the raw request entering the OmniAuth middleware
  Rails.application.config.middleware.insert_before OmniAuth::Builder, OmniAuthDebugMiddleware rescue nil
end
