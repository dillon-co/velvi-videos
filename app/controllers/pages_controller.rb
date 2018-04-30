class PagesController < ApplicationController
  def landing
  end

  def privacy
  end

  def landing_page_drawing
    @raffle_email = RaffleEmail.new
  end

  def color_fun
  end
end
