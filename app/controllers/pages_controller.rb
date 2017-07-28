class PagesController < ApplicationController
  def landing
  end

  def privacy
  end

  def color_fun
    @color_array = []
    112.times { @color_array << '#703382'}
    51.times { @color_array << '#8F7946'}
    130.times { @color_array << '#47CE9A'}
    @c = @color_array.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle.shuffle
  end
end
