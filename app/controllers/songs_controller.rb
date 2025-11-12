class SongsController < ApplicationController
  def show
    @song = Song.find(params[:id])
    @reviews = @song.reviews.order(created_at: :desc)
    @recommendations = AnalyticsService.new(current_user).recommendations_for_song(@song, current_user)
  end

  def index
  end
end
