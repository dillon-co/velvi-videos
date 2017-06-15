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

require 'test_helper'

class VideoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
