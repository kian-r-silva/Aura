# Development-only middleware to log incoming requests to the OmniAuth endpoints
if Rails.env.development?
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
        Rails.logger.debug "[OmniAuthDebug] Cookie header: #{env['HTTP_COOKIE'].inspect}"
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
        Rails.logger.debug "[OmniAuthDebug] session['omniauth.state'] = #{sess && sess['omniauth.state'].inspect}"
        Rails.logger.debug "[OmniAuthDebug] session['_csrf_token'] present? #{sess && sess['_csrf_token'].present?}"
      end

      @app.call(env)
    end
  end

  # Insert before OmniAuth so we can inspect the raw request entering the OmniAuth middleware
  Rails.application.config.middleware.insert_before OmniAuth::Builder, OmniAuthDebugMiddleware rescue nil
end
