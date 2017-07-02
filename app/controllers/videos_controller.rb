class VideosController < ApplicationController
  ## TODO Make a modal for loading screen
  ## add bootstrap
  def new
  end

  def show
    @video = Video.find(params[:id])
    session[:vid_id] = params[:id]
  end

  def index
    puts session[v]
    if current_user.videos.present?
      @videos = current_user.videos.all
    end
  end

  def upload_confirmation
    video = Video.find(params[:vid_id])
    video.upload_to_youtube
    redirect_to video_path(video)
    flash[:success] = "Successfully Uploaded To Youtube!"
  end

  def check_video_progress
    vid = Video.find(params[:vid_id])
    respond_to do |format|
      format.json { render json: { done_editing: vid.done_editing }}
    end
  end

  def create_new_video
    current_user.update(email: params[:user_email])
    vid = current_user.videos.create(title: "#{Time.now.strftime("%m/%d/%Y")}-video", video_type: params[:version])
    current_user.call_movie_creation_worker
    respond_to do |format|
       format.json { render json: { video_id: vid.id } }
    end
  end
end
