class VideosController < ApplicationController
  ## TODO Make a modal for loading screen
  ## add bootstrap
  def new
  end

  def show
    @video = Video.find(params[:id])
  end

  def index
    if current_user.videos.present?
      @videos = current_user.videos.all
    end
  end

  def create_new_video
    current_user.get_videos_and_add_them_together
    redirect_to videos_path
  end

end
