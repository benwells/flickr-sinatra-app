require 'sinatra/base'
require "sinatra/config_file"
require 'rack-flash'

class FlickrApp < Sinatra::Base
  register Sinatra::FormKeeper
  register Sinatra::ConfigFile
  use Rack::flash

  configure do
    set :environment, :production
    enable :sessions
    set :session_secret, "Session Secret for shotgun development"
    set :protection, :except => :frame_options
    config_file "config/settings.yml"
  end

  # initializer route More words

  # View photos attached to application (main view)

  # edit single photo info

  #delete photo

  #upload new photo

end
