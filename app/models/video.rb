# == Schema Information
#
# Table name: videos
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  music_url     :string
#  non_music_url :string
#

class Video < ApplicationRecord
  belongs_to :user
  
end
