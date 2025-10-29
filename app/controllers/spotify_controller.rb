require 'net/http'
require 'json'

class SpotifyController < ApplicationController
  before_action :require_login

  def my_tracks
    token = current_user.spotify_access_token_with_refresh!
    return redirect_to root_path, alert: 'Spotify not connected' unless token

    uri = URI('https://api.spotify.com/v1/me/tracks?limit=20')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    @items = res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body)['items'] : []
  rescue StandardError => e
    Rails.logger.error("Spotify API error: #{e.message}")
    @items = []
  end
end