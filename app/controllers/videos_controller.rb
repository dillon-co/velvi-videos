class VideosController < ApplicationController

  def new
  end

  def show
    @video = Video.find(params[:id])
  end

  def index
    @videos = Vieo.all
  end
end
