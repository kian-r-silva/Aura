class AlbumsController < ApplicationController
  def index
    @albums = Album.all.order(:title)
  end

  def show
    @album = Album.find(params[:id])
    @review = Review.new
  end

  def new
    @album = Album.new
  end

  def create
    @album = Album.new(album_params)
    if @album.save
      redirect_to @album, notice: "Album created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def album_params
    params.require(:album).permit(:title, :artist, :year)
  end
end
