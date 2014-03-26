require 'sinatra/base'
require "sinatra/config_file"


class FlickrApp < Sinatra::Base
  register Sinatra::FormKeeper
  register Sinatra::ConfigFile
  register Sinatra::Flash
  # use Rack::flash

  configure do
    set :environment, :production
    enable :sessions
    set :session_secret, "Session Secret for shotgun development"
    set :protection, :except => :frame_options
    config_file "config/settings.yml"
  end

  # root route (really for testing only)
  get '/' do
    # flash[:notice] = "testing flash"
    haml :root
  end
  # initializer route

  # View photos attached to application (main view)

  # edit single photo info

  #delete photo

  #upload new photo

end
