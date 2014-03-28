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

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    #redirect line for Brandon working on uploads
    redirect '/upload'

    #redirect line for Ben working on viewing vids
    # redirect '/list/:page'
  end


  # View photos attached to application (main view)
  get '/list' do
    "route created"
  end

  # edit single photo info

  #delete photo

  #upload new photo
  ##############################################################
  get '/upload' do
    haml :upload
  end

  post '/upload' do
    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    form do
      field :file, :present => true
    end

    if form.failed?
      flash[:notice] = "You must choose a file."
      redirect '/upload';
    else

      tmpfile = params[:file][:tempfile]

      # upload the file
      
      #response = flickr.upload_photo path, :title => (params[:title] + ""), :description => (params[:description] + ""), :tags => (session['visitor_id'] + " " + session['app_id']), :is_public => 0, :hidden => 0
      response = flickr.upload_photo tmpfile, :title => (params[:title] + ""), :description => (params[:description] + ""), :is_public => 0, :hidden => 0

           
      if response["stat"] == "ok"
        #newPhotoId = response['photoid']
        #newPhotoTicket = response['ticketid']
        flash[:notice] = "Photo Uploaded Successfully."
        redirect "/upload"
      else
        #flash[:notice] = "Oops, something went wrong. Please try again."
        flash[:notice] = "#{response['stat']} #{response['photoid']} #{response['ticketid']}"
        redirect "/upload"
      end
    end
  end

end
