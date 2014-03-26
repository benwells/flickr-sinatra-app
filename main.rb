require 'sinatra/base'
require "sinatra/config_file"
require 'flickraw'


class FlickrApp < Sinatra::Base
  register Sinatra::FormKeeper
  register Sinatra::ConfigFile
  register Sinatra::Flash

  configure do
    set :environment, :production
    enable :sessions
    set :session_secret, "Session Secret for shotgun development"
    set :protection, :except => :frame_options
    config_file "config/settings.yml"
  end

  # root route (really for testing only)
  get '/list' do
    # flash[:notice] = "testing flash"
    haml :root
  end

  # initializer route
  get '/:api_key/:shared_secret/:access_token/:access_secret' do
    # flash[:notice] = "testing flash"
    session['api_key'] = params[:api_key];
    session['shared_secret'] = params[:shared_secret];
    session['access_token'] = params[:access_token];
    session['access_secret'] = params[:access_secret];

    FlickRaw.shared_secret= session['shared_secret']
    FlickRaw.api_key = session['api_key']
    #
    token = flickr.get_request_token
    session['access_token'] = token["oauth_token"];
    session['access_secret'] = token["oauth_token_secret"];
    # flickr.access_token = session['access_token']
    # flickr.access_secret = session['access_secret']

    list = flickr.photos.getRecent
    "#{list.to_s}"
    # "#{flickr}"
  end

  # View photos attached to application (main view)

  # edit single photo info

  #delete photo

  #upload new photo

end
