# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  provider               :string
#  uid                    :string
#
require 's3_store'

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:instagram]

  has_many :videos
  after_create :create_video_dir

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid, token: auth.credentials.token).first_or_create do |user|
      user.email = "#{auth.info.nickname}@instagram.com"
      user.password = Devise.friendly_token[0,20]
    end
  end

  def get_videos_and_add_them_together
    create_video_dir
    get_videos_from_instagram
    add_videos_to_text_file
    create_video
    delete_videos
    save_movies_to_bucket
  end

  def get_videos_from_instagram
    i = open("https://api.instagram.com/v1/users/#{uid}/media/recent/?access_token=#{token}")
    client_attributes = OpenStruct.new(JSON.parse(i.read))
    data = JSON.parse(client_attributes.data.to_json, object_class: OpenStruct)
    videos = data.select {|d| d if d["type"] == 'video'}
    save_and_resize(videos)
  end

  def save_and_resize(videos)
    urls_titles_and_sizes = get_video_urls_titles_and_sizes(videos)
    save_videos_to_folder(urls_titles_and_sizes)
    resize_videos_with_padding(urls_titles_and_sizes)
  end

  def get_video_urls_titles_and_sizes(videos)
    urls_titles_and_sizes = videos.map.with_index do |v, i|
      { name: "video_#{i}",
        video_url: v['videos']['standard_resolution']['url'],
        size: { width: v['videos']['standard_resolution']['width'].to_i,
                height: v['videos']['standard_resolution']['height'].to_i
              }
      }
    end
    urls_titles_and_sizes
  end

  def save_videos_to_folder(videos)
    videos.each do |video|
      new_file_path = "#{video_folder}/#{video[:name]}.mp4"
      open(new_file_path, "wb") do |file|
        file.print open(video[:video_url]).read
      end
    end
  end

  def resize_videos_with_padding(urls_titles_and_sizes)
    urls_titles_and_sizes.each do |video|
      video_path = "#{video_folder}/#{video[:name]}.mp4"
      output_video = "#{video_folder}/output_#{video[:name]}.mp4"
      video_placement = calculate_padding_placement(video)
      run_size_and_padding_command = "ffmpeg -i #{video_path} -vf 'scale=-1:360, pad=640:360:#{video_placement}:0:black' #{output_video}"
      `#{run_size_and_padding_command}`
      File.delete(video_path)
    end
  end

  def calculate_padding_placement(video)
    if video[:size][:width] == "360" && video[:size][:height] == 640
      return 0
    else
      scaler = 360.0 / video[:size][:height].to_f
      video_width = video[:size][:width] * scaler
      pad_size = (640 - video_width) / 2
      return pad_size
    end
  end

  def add_videos_to_text_file
    movie_file = open(movie_text_file, "wb")
    Dir.glob("#{video_folder}/*.mp4").each do |video|
      if video.split('/').last.split('_').length > 1
        movie_file.write("file '#{video.split('/').last}'")
        movie_file.write("\n")
      end
    end
    movie_file.close
  end

  def create_video
    vid = videos.create(title: "#{Time.now.strftime("%m/%d/%Y")}-video")
    command = "ffmpeg -f concat -safe 0 -i #{video_folder}/movies.txt -c copy #{video_folder}/output#{vid.id}.mp4"
    `#{command}`
    add_audio_to_video(vid.id)
  end

  def delete_videos
    Dir.glob("#{video_folder}/*.mp4").each do |video|
      if video.split('/').last.split('_').length > 1
        File.delete(video)
      end
    end
    movie_list = open("#{video_folder}/movies.txt", "wb")
    movie_list.truncate(0)
  end

  def save_movies_to_bucket
    videos = Dir.glob("#{video_folder}/*.mp4").each do |v|
      s3_store = S3Store.new(v)
      s3_store.store
      save_type_of_video_url(v, s3_store.url)
    end
  end

  def save_type_of_video_url(video_string, s3_store_url)
    v = video_string.split("/").last.split(".").first
    v.split(/\d+/).length > 1 ? Video.find(v[/\d+/]).update(music_url: s3_store_url) : Video.find(v[/\d+/]).update(non_music_url: s3_store_url)
  end

  def add_audio_to_video(video_id)
    c = "ffmpeg -i #{video_folder}/output#{video_id}.mp4 -i #{audio_folder}/no_diggity.mp3 -c copy -map 0:0 -map 1:0 -shortest #{video_folder}/output#{video_id}audio.mp4"
    `#{c}`
  end

  def video_folder
    "#{Rails.root.to_s}/public/videos/#{id}"
  end

  def audio_folder
    "#{Rails.root.to_s}/public/audio"
  end

  def movie_text_file
    "#{video_folder}/movies.txt"
  end

  def create_video_dir
    Dir.mkdir("#{video_folder}")
  end

  def remove_video_dir
    c = "rm -rf #{Rails.root.to_s}/public/videos/#{id}"
    `#{c}`
  end
end
