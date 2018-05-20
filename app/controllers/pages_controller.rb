class PagesController < ApplicationController
  def landing
  end

  def privacy
  end

  def landing_page_drawing
    response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM https://www.youtube.com"
    @raffle_email = RaffleEmail.new
  end

  def color_fun
  end
end
