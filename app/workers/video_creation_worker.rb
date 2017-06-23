class VideoCreationWorker
  include Sidekiq::Worker
  def perform(user_id)
    User.find(user_id).get_videos_and_add_them_together
  end
end
