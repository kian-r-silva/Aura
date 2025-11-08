class MusicbrainzController < ApplicationController
  # JSON search endpoint used by client-side autocomplete
  def search
    query = (params[:q] || params[:query]).to_s.strip
    Rails.logger.debug "[MusicbrainzController#search] incoming q=#{query.inspect} ip=#{request.remote_ip}"
    return render json: [] if query.length < 2

    cache_key = "mb_search/#{query.downcase}"
    contact_email = current_user&.email
    results = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      Rails.logger.debug "[MusicbrainzController#search] cache miss for #{cache_key}; calling MusicbrainzClient (contact=#{contact_email.inspect})"
      MusicbrainzClient.search_recordings(query, limit: 10, contact_email: contact_email)
    end

    Rails.logger.debug "[MusicbrainzController#search] returning #{results.length} results for q=#{query.inspect} (cache_key=#{cache_key})"
    render json: results, status: :ok
  end
end

