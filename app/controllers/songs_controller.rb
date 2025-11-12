class SongsController < ApplicationController
  def show
    @song = Song.find(params[:id])
    # list reviews for this song ordered by created_at desc
    @reviews = @song.reviews.order(created_at: :desc)
  end

  def index
  end
end
