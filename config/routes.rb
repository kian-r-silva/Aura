Rails.application.routes.draw do
  root "albums#index"

  resources :users, only: %i[new create show]
  resource  :session, only: %i[new create destroy]
  resources :albums, only: %i[index show new create] do
    resources :reviews, only: %i[create]
  end
  # top-level review routes for creating reviews not tied to an existing album yet
  resources :reviews, only: %i[new create]

  get '/auth/spotify/callback', to: 'spotify_auth#callback'
  get '/auth/failure', to: 'spotify_auth#failure'
  delete '/disconnect_spotify', to: 'spotify_auth#disconnect', as: :disconnect_spotify

  # Development-only debug routes to inspect session and submit a manual auth form.
  # Also enable when OMNIAUTH_DEBUG=true so we can safely debug on Heroku for a short time.
  if Rails.env.development? || ENV['OMNIAUTH_DEBUG'] == 'true'
    get '/debug/session', to: 'debug#session'
    get '/debug/auth_form', to: 'debug#auth_form'
  end
  
  # MusicBrainz JSON search endpoint used by the manual review autocomplete
  get '/musicbrainz/search', to: 'musicbrainz#search', defaults: { format: :json }

  # Create a review directly from a MusicBrainz selection (AJAX POST)
  post '/reviews/musicbrainz_create', to: 'reviews#musicbrainz_create', as: :musicbrainz_create_review
  
  # Spotify recent tracks
  get '/spotify/recent', to: 'spotify#recent', as: :spotify_recent
  # Server endpoint that returns a fresh access token for the logged-in user (used by Web Playback SDK)
  get '/spotify/token', to: 'spotify_auth#token', as: :spotify_token
  # Search Spotify tracks (q param)
  get '/spotify/search', to: 'spotify#search', as: :spotify_search
end
