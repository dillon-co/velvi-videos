class RaffleEmail < ApplicationRecord
  after_create :deliver_welcome_email

  def deliver_welcome_email
    AwsMailer.welcome_email(self).deliver
  end
end
