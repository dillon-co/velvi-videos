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

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
