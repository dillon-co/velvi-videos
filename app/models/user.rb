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

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:instagram]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid, token: auth.credentials.token).first_or_create do |user|
      binding.pry
      user.email = "#{auth.info.nickname}@instagram.com"
      user.password = Devise.friendly_token[0,20]
    end
  end

  def instagram_data
    i = open("https://api.instagram.com/v1/users/#{uid}/media/recent/?access_token=#{token}")
    client_attributes = OpenStruct.new(JSON.parse(i.read))
    data = client_attributes.data
  end
end
