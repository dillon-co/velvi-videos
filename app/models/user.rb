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
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  provider               :string
#  uid                    :string
#  token                  :string
#  money_in_account       :float            default(0.0)
#
# require 'video_creation_worker'
require 's3_store'
require 'aws-sdk'

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

  def call_movie_creation_worker
    VideoCreationWorker.perform_async(id)
  end

  def get_videos_and_add_them_together
    create_video_dir
    puts "\n\n\nDownloading videos\n\n\n"
    get_videos_from_instagram
    puts "\n\n\nadding to text file\n\n\n"
    add_videos_to_text_file
    puts "\n\n\nadding video together\n\n\n"
    add_videos_together_with_music
    delete_videos
    puts "\n\n\nsaving movies\n\n\n"
    save_movies_to_bucket
  end

  def get_videos_from_instagram
    i = open("https://api.instagram.com/v1/users/#{uid}/media/recent/?access_token=#{token}")
    client_attributes = OpenStruct.new(JSON.parse(i.read))
    data = JSON.parse(client_attributes.data.to_json)
    videos = data.select {|d| d if d["type"] == 'video'}
    # binding.pry
    puts "saving and resizing"
    save_and_resize(videos.first(15))
    # download_instagram_videos(videos.first(15))
  end


  def save_and_resize(videos)
    urls_titles_and_sizes = get_video_urls_titles_and_sizes(videos)
    save_videos_to_folder(urls_titles_and_sizes)
    resize_videos_with_padding(urls_titles_and_sizes)
  end

  def get_video_urls_titles_and_sizes(videos)
    urls_titles_and_sizes = videos.map.with_index do |v, i|
      { name: "video#{i}",
        video_url: v['videos']['standard_resolution']['url'],
        size: { width: v['videos']['standard_resolution']['width'].to_i,
                height: v['videos']['standard_resolution']['height'].to_i
              }
      }
    end
    urls_titles_and_sizes
  end

  def save_videos_to_folder(videos)
    Parallel.each(videos, in_threads: 15) do |video|
      new_file_path = "#{video_folder}/#{video[:name]}.mpeg"
      open(new_file_path, "wb") do |file|
        file.print open(video[:video_url]).read
      end
    end
  end

  def resize_videos_with_padding(urls_titles_and_sizes)
    counter = 0
    batch_size = 4
    urls_titles_and_sizes.each do |video|
      puts counter += 1
      video_path = "#{video_folder}/#{video[:name]}.mpeg"
      output_video = "#{video_folder}/output_#{video[:name]}.mpeg"
      video_placement = calculate_padding_placement(video)
      run_size_and_padding_command = "ffmpeg -loglevel panic -i #{video_path} -vf 'scale=-1:640, pad=1138:640:#{video_placement}:0:black' #{output_video}"
      `#{run_size_and_padding_command}`
      File.delete(video_path)
    end
  end

  def calculate_padding_placement(video)
    if video[:size][:width] == 640 && video[:size][:height] == 360
      return 0
    else
      scaler = 640.0 / video[:size][:height].to_f
      video_width = video[:size][:width] * scaler
      pad_size = (1138 - video_width) / 2
      return pad_size
    end
  end

  def add_videos_to_text_file
    movie_file = open(movie_text_file, "wb")
    Dir.glob("#{video_folder}/*.mpeg").each do |video|
      if video.split('/').last.split('_').length > 1
        movie_file.write("file '#{video.split('/').last}'")
        movie_file.write("\n")
      end
    end
    movie_file.close
  end

  def add_videos_together_with_music
    vid = videos.last
    command = "ffmpeg -f concat -safe 0 -i #{video_folder}/movies.txt -c copy #{video_folder}/output#{vid.id}.mpeg"
    `#{command}`
    if vid.video_type == 'free'
      puts "\n\n\nadding watermark\n\n\n"
      add_watermark_to_video(vid.id)
    else
      c = "ffmpeg -i #{video_folder}/output#{vid.id}.mpeg -vcodec copy -acodec copy #{video_folder}/output#{vid.id}.mp4"
      `#{c}`
    end
    puts "\n\n\nadding music\n\n\n"
    add_audio_to_video(vid.id)
    File.delete("#{video_folder}/output#{vid.id}.mov")
  end

  def delete_videos
    Dir.glob("#{video_folder}/*.mpeg").each do |video|
      if video.split('/').last.split('_').length > 1
        File.delete(video)
      end
    end
    movie_list = open("#{video_folder}/movies.txt", "wb")
    movie_list.truncate(0)
  end

  def save_movies_to_bucket
    videos = Dir.glob("#{video_folder}/*.mp4").each do |v|
      puts "\n\n\n\n\ngrabbing video #{v}\n\n\n\n\n"
      s3_store = S3Store.new(v)
      s3_store.store
      puts "\n\n\n\n\nsaving video to database\n\n\n\n\n"
      save_type_of_video_url(v, s3_store.url)
    end
  end

  def save_type_of_video_url(video_string, s3_store_url)
    v = video_string.split("/").last.split(".").first
    if v.split(/\d+/).length > 1
      #check if file being saved to db is a movie with a song in the background
      Video.find(v[/\d+/]).update(music_url: s3_store_url, done_editing: true)
    else
      Video.find(v[/\d+/]).update(non_music_url: s3_store_url)
    end
  end

  def add_audio_to_video(video_id)
    c = "ffmpeg -i #{video_folder}/output#{video_id}.mov -i #{audio_folder}/no_diggity.mp3 -c copy -map 0:0 -map 1:0 #{video_folder}/output#{video_id}audio.mp4"
    `#{c}`
  end

  def add_watermark_to_video(video_id)
    # puts "skipping watermark for debugging"
    watermark_command = "ffmpeg -i #{video_folder}/output#{video_id}.mpeg -i #{watermark} -filter_complex 'overlay=1:600' -y #{video_folder}/output#{video_id}.mp4"
    `#{watermark_command}`
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

  def watermark
    "#{Rails.root.to_s}/public/watermarks/rsz_1watermark.png"
  end

  def create_video_dir
    remove_video_dir
    Dir.mkdir("#{video_folder}")
  end

  def remove_video_dir
    c = "rm -rf #{Rails.root.to_s}/public/videos/#{id}"
    `#{c}`
  end



##########################################################

  # def create_users_movies
  #   create_video_dir
  #   get_videos_from_instagram
  #   add_videos_together_from_bucket
  # end
  #
  # def download_instagram_videos(videos)
  #   urls_titles_and_sizes = get_video_urls_titles_and_sizes(videos)
  #   save_clips_to_bucket(urls_titles_and_sizes)
  # end
  #
  # def save_clips_to_bucket(urls_titles_and_sizes)
  #   s3 = Aws::S3::Resource.new
  #   bucket = s3.bucket('velvi-instagram-clips')
  #   Parallel.each(urls_titles_and_sizes, in_threads: 15) do |v|
  #     puts "downloading #{v[:name]}"
  #     obj = bucket.object("#{id}/#{v[:name]}.mpeg")
  #     # File.open(v, 'rb') do |file|
  #     obj.put(body: open(v[:video_url]).read, acl: "public-read")
  #     # end
  #   end
  # end
  # #
  # def add_videos_together_from_bucket
  #   transcoder = Aws::ElasticTranscoder::Client.new
  #
  #   input_videos = get_all_videos_from_bucket
  #   presets = transcoder.create_preset(
  #     name: "instagram resizing preset",
  #     container: "mpeg",
  #     description: "Preset for stitching together all instagram videos",
  #     video:{
  #        max_width: "auto",
  #        max_height: "auto",
  #        sizing_policy: 'Fit',
  #        padding_policy: 'Pad',
  #        codec: 'H.264',
  #        bit_rate: '192',
  #        frame_rate: '30',
  #        keyframes_max_dist: "30",
  #        fixed_gop: "true",
  #        codec_options: {
  #          "Level": '3.1',
  #          "MaxReferenceFrames": '16',
  #          "Profile": 'high',
  #         #  "key_frame_max_dist": "30",
  #          "FixedGOP": "true",
  #        },
  #        display_aspect_ratio: '16:9'
  #     },
  #     thumbnails: {
  #       format: "jpg",
  #       interval: "20",
  #       # resolution: "ThumbnailResolution",
  #       # aspect_ratio: "AspectRatio",
  #
  #       max_width: "auto",
  #       max_height: "auto",
  #       padding_policy: 'Pad',
  #       sizing_policy: "Fit"
  #     })
  #   j = transcoder.create_job(pipeline_id: '1497983016180-i9agda',
  #   inputs: input_videos,
  #   output: {
  #      key: "full_output_video.mpeg",
  #      preset_id: presets[:preset][:id]
  #   })
  # end
  #
  # def get_all_videos_from_bucket
  #   s3 = Aws::S3::Resource.new
  #   titles = s3.bucket('velvi-instagram-clips').objects(prefix: "#{id}").map do |v|
  #     {key: v.key, frame_rate: "auto",
  #      resolution: "auto",
  #      aspect_ratio: "auto",
  #      interlaced: "auto",
  #      container: "auto"}
  #   end
  #   titles
  # end

end
