class SubscriptionsController < ApplicationController
  require "stripe"

  def create
    subscription = Stripe::Plan.create(
      :amount => (params[:amount].to_i)*100,
      :interval => params[:interval],
      :name => params[:name],
      :currency => 'usd',
      :trial_plan => null
      :id => SecureRandom.uuid # This ensures that the plan is unique in stripe
    )
    #Save the response to your DB
    flash[:notice] = "Plan successfully created"
    redirect_to '/subscription'
  end

  def stripe_checkout
    @amount = 10
    #This will create a charge with stripe for $10
    #Save this charge in your DB for future reference
    charge = Stripe::Charge.create(
                    :amount => @amount * 100,
                    :currency => "usd",
                    :source => params[:stripeToken],
                    :description => "Test Charge"
    )
    flash[:notice] = "Successfully created a charge"
    redirect_to '/subscription'
  end

  def plans
  end

  def index
  end
end
