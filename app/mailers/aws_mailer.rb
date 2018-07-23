class AwsMailer < ApplicationMailer
  def welcome_email(user)
    @name = user.name
    # @email = from.
    @message = "Thanks for your interest in Velvi! by signing up, You're helping
     us achieve our mission, Which is to create technology that gives everyone the
     abilities of people like Da Vinci and Motzart. I'm excited that
     you're part of the journey!
     \n\nThanks,\n\n\n\n-Dillon Cortez,\nFounder & C.E.O"
     mail(:to=>user.email, :subject=>"Welcome! A note from the founder.")
  end
end
