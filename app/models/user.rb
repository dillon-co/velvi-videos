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
#  youtube_uid            :string
#  youtube_token          :string
#  youtube_name           :string
#  youtube_refresh_token  :string
#  event_nick_name        :string
#  sponsored              :boolean          default(FALSE)
#  subscribed             :boolean          default(FALSE)
#  num_followers          :integer
#

require 's3_store'
require 'aws-sdk'

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:instagram, :google_oauth2]

  has_many :videos
  has_many :events
  after_create :create_video_dir

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid, token: auth.credentials.token).first_or_create do |user|
      user.email = "#{auth.info.nickname}@instagram.com"
      user.password = Devise.friendly_token[0,20]
    end
  end

  def from_youtube(auth)
    puts "\n\n\n#{auth}\n\n\n"
    self.update(youtube_uid: auth['uid'],
                youtube_token: auth['credentials']['token'],
                youtube_refresh_token: auth['credentials']['refresh_token'],
                youtube_name: auth['info']['name'])
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

  def create_specific_video_for_user(tag)
    create_video_dir
    puts "\n\n\nDownloading videos\n\n\n"
    get_certain_videos_from_instagram(tag)
    puts "\n\n\nadding to text file\n\n\n"
    add_videos_to_text_file
    puts "\n\n\nadding video together\n\n\n"
    add_videos_together_with_music
    delete_videos
    puts "\n\n\nsaving movies\n\n\n"
    save_movies_to_bucket
  end

  def get_videos_from_instagram
    i = open("https://api.instagram.com/v1/users/#{uid}/media/recent/?access_token=#{token}&count=40")
    client_attributes = OpenStruct.new(JSON.parse(i.read))
    data = JSON.parse(client_attributes.data.to_json)
    videos = data.select {|d| d if d["type"] == 'video'}
    carousels = data.select {|d| d if d['type'] == 'carousel'}
    carousels.each do |c|
      c_videos = c.select{|m| m if m['type'] == 'video' }
      videos << c_videos.first
    end
    puts "saving and resizing"
    save_and_resize(videos.first(15))
  end

  def get_posts_from_instagram
    i = open("https://api.instagram.com/v1/users/#{uid}/media/recent/?access_token=#{token}&count=40")
    client_attributes = OpenStruct.new(JSON.parse(i.read))
    data = JSON.parse(client_attributes.data.to_json)
    return data
  end

  def get_basic_profile_data
    i = open("https://api.instagram.com/v1/users/#{uid}?access_token=#{token}&count=40")
    client_attributes = OpenStruct.new(JSON.parse(i.read))
    data = JSON.parse(client_attributes.data.to_json)
    return data
  end

  def get_num_followers
    data = get_basic_profile_data
    number_of_followers = data["counts"]["follows"]
    self.update(num_followers: number_of_followers)
  end

  def get_certain_videos_from_instagram(tag)
    data = get_data_from_instagram
    instagram_videos = data.select {|d| d if d["type"] == 'video'}
    carousels = data.select {|d| d if d['type'] == 'carousel'}
    carousels.each do |c|
      c_videos = c.select{|m| m if m['type'] == 'video' }
      instagram_videos << c_videos.first
    end
    vids = instagram_videos.select {|v| v if v != nil && v['tags'].include?(tag) }
    save_and_resize(vids)
  end

  def save_and_resize(videos)
    if videos.length > 0
        urls_titties_and_sizes = get_video_urls_titles_and_sizes(videos)
        urls_titles_and_sizes = urls_titties_and_sizes.select {|obj| obj if obj[:video_url] != '' }
        save_videos_to_folder(urls_titles_and_sizes)
        resize_videos_with_padding(urls_titles_and_sizes)
    else
      videos.last.update(done_editing: true, no_instagram_videos: true)
    end
  end

  def get_video_urls_titles_and_sizes(videos)
    urls_titles_and_sizes = []
    Parallel.each_with_index(videos, in_threads: 15) do |v, i|
      v != nil ? vid_url = v['videos']['standard_resolution']['url'] : vid_url = ""
      v != nil ? wid = v['videos']['standard_resolution']['width'] : wid = '0'
      v != nil ? hei = v['videos']['standard_resolution']['height'] : hei = '0'
      h = { name: "video#{i}",
            video_url: vid_url,
            size: { width: wid,
                height: hei
              }
            }
      urls_titles_and_sizes << h
    end
    urls_titles_and_sizes
  end

  def save_videos_to_folder(videos)
    Parallel.each(videos, in_threads: 15) do |video|
      if video[:video_url] != ''
        new_file_path = "#{video_folder}/#{video[:name]}.mp4"
        open(new_file_path, "wb") do |file|
          file.print open(video[:video_url]).read
        end
      end
    end
  end

  def resize_videos_with_padding(urls_titles_and_sizes)
    counter = 0
    batch_size = 4
    Parallel.each(urls_titles_and_sizes, in_threads: 2) do |video|
      puts counter += 1
      video_path = "#{video_folder}/#{video[:name]}.mp4"
      output_video = "#{video_folder}/output_#{video[:name]}.mp4"
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
      pad_size = (1140 - video_width) / 2
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

  def add_videos_together_with_music
    vid = videos.last
    concat_all_videos = "ffmpeg -f concat -safe 0 -i #{video_folder}/movies.txt -c copy #{video_folder}/output#{vid.id}.mp4"
    `#{concat_all_videos}`
    # if vid.video_type == 'free'
    #   puts "\n\n\nadding watermark\n\n\n"
    #   add_watermark_to_video(vid.id)
    # else
    # c = "ffmpeg -i #{video_folder}/output#{vid.id}.mpeg -vcodec copy -acodec copy #{video_folder}/output#{vid.id}.mp4"
    # `#{c}`
    # end
    # binding.pry
    # File.delete("#{video_folder}/output#{vid.id}.mpeg")
    puts "\n\n\nadding music\n\n\n"
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
      puts "#{video_string}: #{s3_store_url}"
      #check if file being saved to db is a movie with a song in the background
      Video.find(v[/\d+/]).update(music_url: s3_store_url, done_editing: true)
    else
      Video.find(v[/\d+/]).update(non_music_url: s3_store_url)
    end
  end

  def add_audio_to_video(video_id)
    c = "ffmpeg -i #{video_folder}/output#{video_id}.mp4 -i #{audio_folder}/no_diggity.mp3 -c copy -map 0:0 -map 1:0 -shortest #{video_folder}/output#{video_id}audio.mp4"
    `#{c}`
  end

  def add_watermark_to_video(video_id)
    # puts "skipping watermark for debugging"
    puts "skipping watermark for Speed"
    # watermark_command = "ffmpeg -i #{video_folder}/output#{video_id}.mpeg -i #{watermark} -filter_complex 'overlay=1:600' -y #{video_folder}/output#{video_id}.mp4"
    # `#{watermark_command}`
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

  def self.update_all_followers
    self.all.each do |u|
      begin
        u.get_num_followers
      rescue
        next
      end
    end
  end

  def self.get_average_num_followers
    arr_of_num_of_followers = self.all.map{ |u| u.num_followers.present? ? u.num_followers :  nil }.compact
    divider = arr_of_num_of_followers.length
    sum_of_all_nums = arr_of_num_of_followers.inject(&:+)
    puts sum_of_all_nums / divider
  end

  def self.asdf
    self.update_all_followers
    self.get_average_num_followers
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
  # def get_event_videos_from_users
  #   instagram_videos = []
  #   event_users.each do |u|
  #     begin
  #       i = open("https://api.instagram.com/v1/users/#{u[:uid]}/media/recent/?access_token=#{u[:token]}&count=3")
  #       client_attributes = OpenStruct.new(JSON.parse(i.read))
  #       data = JSON.parse(client_attributes.data.to_json)
  #       instagram_videos << data.select {|d| d if d["type"] == 'video' && d["tags"].include?("jumpfest2017")}
  #     rescue
  #       puts "poop"
  #       next
  #     end
  #   end
  #   puts instagram_videos
  #   instagram_videos
  # end
  #
  # def create_event_videos
  #   vids = get_event_videos_from_users
  #   save_without_resizing(vids)
  # end
  #
  # def get_video_urls(videos)
  #   puts videos.class
  #   urls_and_titles = []
  #   vids = videos.select {|a| a if a != []}
  #   vids.flatten.each_with_index do |v, i|
  #
  #     vid_url = v['videos']['standard_resolution']['url']
  #     urls_and_titles << {video_url: vid_url, name: "video#{i}"}
  #   end
  #   urls_and_titles
  # end
  #
  # def save_without_resizing(videos)
  #   urls_titties_and_sizes = get_video_urls(videos)
  #   urls_titles_and_sizes = urls_titties_and_sizes.select {|obj| obj if obj[:video_url] != '' }
  #   save_videos_to_folder(urls_titles_and_sizes)
  # end


end
