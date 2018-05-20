# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
puts "\n\n\nadding video path to assets\n\n\n"
Rails.application.config.assets.paths << "/app/assets/videos"
Rails.application.config.assets.precompile += %w( VideoJS.eot VideoJS.svg VideoJS.ttf VideoJS.woff )
Rails.application.config.assets.precompile += %w( video-js.swf vjs.eot vjs.svg vjs.ttf vjs.woff )
# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
