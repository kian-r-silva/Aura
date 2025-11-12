class AlbumsController < ApplicationController
  def index
    # Albums are deprecated — redirect to songs index which is now the main landing page
    redirect_to songs_path
  end

  def show
    # Albums are deprecated — redirect to songs index
    redirect_to songs_path
  end

  def new
    # Albums are deprecated — redirect to songs index
    redirect_to songs_path
  end

  def create
    # Albums are deprecated — accept request but redirect to songs index
    redirect_to songs_path, notice: "Albums are deprecated. You can add reviews for songs instead."
  end

  private

  def album_params
    params.require(:album).permit(:title, :artist, :year)
  end
end
