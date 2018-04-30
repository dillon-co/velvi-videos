class RaffleEmailsController < ApplicationController
  def create
    raffle_email = RaffleEmail.new(raffle_email_params)
    if raffle_email.email != "" && raffle_email.name != ""
      if RaffleEmail.find_by(email: raffle_email.email) == nil
        if raffle_email.save
          redirect_to raffle_share_path
        end    
      else
        flash[:alert] = "Looks like that email was already taken!"
        redirect_to root_path(anchor: 'signup-form')
      end
    else
      flash[:alert] = "Whoops! looks like you left some fields blank!"
      redirect_to root_path(anchor: 'signup-form')
    end
  end

  def raffle_share
  end

  private

  def raffle_email_params
    params.require(:raffle_email).permit(:email, :name, :raffle_count)
  end
end
