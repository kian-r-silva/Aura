# Development-only controller to help debug OmniAuth/session issues
class DebugController < ActionController::Base
  # No auth required; this is development helper only

  def session
    render plain: "session keys: #{session.keys.inspect}\nsession dump: #{session.to_hash.inspect}\n"
  end

  def auth_form
    # simple page with a form that POSTs to /auth/spotify (includes authenticity_token)
    render inline: <<-ERB
      <!doctype html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <%= csrf_meta_tags %>
        </head>
        <body>
          <h2>Manual Spotify auth POST</h2>
          <p>This page renders a plain form that POSTs to <code>/auth/spotify</code> and includes the Rails authenticity_token. Use this to verify the POST contains the token and cookies are sent.</p>
          <%= form_tag('/auth/spotify', method: :post) do %>
            <%= submit_tag 'Connect Spotify (manual POST)' %>
          <% end %>
        </body>
      </html>
    ERB
  end
end
