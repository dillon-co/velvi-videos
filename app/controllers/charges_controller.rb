class ChargesController < ApplicationController
  def new
  end

  def create
    # Amount in cents
    @amount = 700

    u = current_user
    total_monies = u.money_in_account

    customer = Stripe::Customer.create(
      :email => params[:stripeEmail],
      :source  => params[:stripeToken]
    )

    charge = Stripe::Charge.create(
      :customer    => customer.id,
      :amount      => @amount,
      :description => 'Rails Stripe customer',
      :currency    => 'usd'
    )

    current_user.update(money_in_account: total_monies+@amount)
    redirect_to root_path

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_charge_path
  end
end
