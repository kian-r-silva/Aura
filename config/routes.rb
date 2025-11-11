Rails.application.routes.draw do
  root "albums#index"

  resources :users, only: %i[new create show]
  resource  :session, only: %i[new create destroy]
  resources :albums, only: %i[index show new create] do
    resources :reviews, only: %i[create]
  end
  # top-level review routes for creating reviews not tied to an existing album yet
  resources :reviews, only: %i[new create]

  resources :songs, only: %i[show]

  get '/auth/spotify/callback', to: 'spotify_auth#callback'
  get '/auth/failure', to: 'spotify_auth#failure'
  delete '/disconnect_spotify', to: 'spotify_auth#disconnect', as: :disconnect_spotify

  # Development-only debug routes to inspect session and submit a manual auth form.
  # These were removed to avoid accidentally exposing session dumps in non-dev environments.
  
  # MusicBrainz JSON search endpoint used by the manual review autocomplete
  get '/musicbrainz/search', to: 'musicbrainz#search', defaults: { format: :json }

  # Create a review directly from a MusicBrainz selection (AJAX POST)
  post '/reviews/musicbrainz_create', to: 'reviews#musicbrainz_create', as: :musicbrainz_create_review
  
  # Spotify recent tracks
  get '/spotify/recent', to: 'spotify#recent', as: :spotify_recent
  # Optional helper endpoint used by tests and the UI to list the user's saved tracks
  get '/spotify/my_tracks', to: 'spotify#my_tracks', as: :spotify_my_tracks
  # Server endpoint that returns a fresh access token for the logged-in user (used by Web Playback SDK)
  get '/spotify/token', to: 'spotify_auth#token', as: :spotify_token
  # Search Spotify tracks (q param)
  get '/spotify/search', to: 'spotify#search', as: :spotify_search

  # Last.fm authentication
  get '/auth/lastfm', to: 'lastfm_auth#auth', as: :lastfm_auth
  get '/auth/lastfm/callback', to: 'lastfm_auth#callback', as: :lastfm_auth_callback
  delete '/disconnect_lastfm', to: 'lastfm_auth#disconnect', as: :disconnect_lastfm
  # Last.fm recent tracks
  get '/lastfm/recent', to: 'lastfm#recent', as: :lastfm_recent
  # Optional helper endpoint used by tests and the UI to list the user's recent tracks
  get '/lastfm/my_tracks', to: 'lastfm#my_tracks', as: :lastfm_my_tracks
  # Server endpoint that returns the session key for the logged-in user
  get '/lastfm/token', to: 'lastfm_auth#token', as: :lastfm_token
  # Search Last.fm tracks (q param)
  get '/lastfm/search', to: 'lastfm#search', as: :lastfm_search
end
