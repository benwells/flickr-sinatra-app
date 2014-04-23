require 'sinatra/base'
require "sinatra/config_file"
require 'flickraw'


class FlickrApp < Sinatra::Base
  register Sinatra::FormKeeper
  register Sinatra::ConfigFile
  register Sinatra::Flash

  configure do
    enable :sessions, :logging
    set :session_secret, "Session Secret for shotgun development"
    set :environment, :development
    set :protection, :except => :frame_options
    config_file "config/settings.yml"
    set :fsesh, nil

    file = File.new("#{settings.environment}.log", 'a+')
    file.sync = true
    use Rack::CommonLogger, file
    STDOUT.reopen(file)
    STDERR.reopen(file)
  end

  #before each route except the init,  set the flickr var from settings
  before /^(?!\/(init))/ do

    #SET SESSIONS FOR DEVELOPMENT ONLY
    session['api_key'] = ENV['flickr_api_key'];
    session['shared_secret'] = ENV['flickr_shared_secret'];
    session['access_token'] = ENV['flickr_access_token'];
    session['access_secret'] = ENV['flickr_access_secret'];
    session['visitor_id'] = ENV['flickr_visitor_id'];
    session['app_id'] = ENV['flickr_app_id'];

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    f = FlickRaw::Flickr.new
    f.access_token = session['access_token']
    f.access_secret = session['access_secret']
    settings.fsesh = f
    #END DEVELOPMENT ONLY BLOCK

    #for production
    @flickr = settings.fsesh
  end

  # initializer route
  get '/init/:api_key/:shared_secret/:access_token/:access_secret/:visitor_id/:app_id' do

    #store params in session
    session['api_key'] = params[:api_key];
    session['shared_secret'] = params[:shared_secret];
    session['access_token'] = params[:access_token];
    session['access_secret'] = params[:access_secret];
    session['visitor_id'] = "u" + params[:visitor_id];
    session['app_id'] = "a" + params[:app_id];

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    f = FlickRaw::Flickr.new
    f.access_token = session['access_token']
    f.access_secret = session['access_secret']
    settings.fsesh = f

    #redirect line for Brandon working on viewing photos
    redirect '/viewphotos/1'
  end

  get '/viewphotos/:page' do
    #get all photos from flickr account
    @userPhotos = @flickr.photos.search(:user_id => "me", :tags => "#{session['visitor_id'].to_s}", :tag_mode => "ALL", :privacy_filter => '5', :per_page => '100',:page => '1')
    @allPhotos = @flickr.photos.search(:user_id => "me", :tags => "#{session['app_id'].to_s}", :tag_mode => "ALL", :privacy_filter => '5', :per_page => '100',:page => '1')

    haml :viewphotos
  end

  get '/view/:id/:farm/:server/:secret' do
    # Just some background info, the link we are building here is just getting the photo from flickr without have to go to the users photo wall.
    # The photos are resized for some reason but you can specfiy how big you want them by adding a flag to the end of the url.
    # There are two separate flags you should be aware of: _m and _b the first makes the photos very small and the other just makes it so
    # the photos are not resized if they are less than a certain height or length. I have the second selected for obvious reasons.
    @source = 'http://farm' + params[:farm] + '.static.flickr.com/' + params[:server] + '/' + params[:id] + '_' + params[:secret] + '_b.jpg'
    haml :view
  end


  # Edit single photo info
  ############################################################
  get '/edit/:photoid' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    @id = params[:photoid]

    @info = flickr.photos.getInfo :photo_id => @id

    haml :edit
  end

  post '/update' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    @title = params["title"]
    @description = params["description"]
    @id = params["photo_id"]

    flickr.photos.setMeta(:photo_id => @id,:title => @title,:description => @description)

    redirect '/viewphotos/1';
  end


  # This takes a list of comma seperated photo ids and the tag you would like to remove.
  ################################
  get '/detach/:photoids/:tag' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    photoId = params[:photoids].to_s


    if photoId != '0'
      photosToDetach = photoId.to_s.split(',');

      photosToDetach.each do |id|


        info = flickr.photos.getInfo :photo_id => id.to_i

        hashResponse = (info.to_hash)

        # This is an array of hashes.
        tags = hashResponse['tags']['tag']

        size = tags.length
        count = 0
        flag = 0

        while count < size do
          if tags[count].to_s == params["tag"]
            flickr.photos.removeTag(:tag_id => tags[count]['id'])
            flag = 1
          end
          count += 1
        end

        if flag != 1
          flash[:notice] = "Error: Photo not found."
        end
        count = 0
        flag = 0
      end
    end

  #delete photo
  #############################################################
  get '/delete/:photoid' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    photoId = params[:photoid]
    photoId = photoId.to_i

    flickr.photos.delete(:photo_id => photoId)

    flash[:notice] = "The photo has been deleted."
    redirect '/viewphotos/1';
  end

  # Note to self, this needs to be updated
  ################################
  get '/attach/:photoids/:tag' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    photoIds = params[:photoids].to_s

    if params[:photoids] != '0'
      photosToAttach = photoIds.split(',')
      photosToAttach.each do |ids|

        flickr.photos.addTags(:photo_id => ids.to_i,:tags => params[:tag].to_s)

      end
    end

    redirect '/viewphotos/1'
  end

  #upload new photo
  ##############################################################
  get '/upload' do
    haml :upload
  end

  post '/upload' do

    form do
      field :file, :present => true
    end

    if form.failed?
      flash[:notice] = "You must choose a file."
      redirect '/upload';
    else

      ##########Form validation##############
      validFile = false
      fileType = params[:file][:type]
      if(fileType == "image/jpeg" || fileType == "image/jpg" || fileType == "image/png")
        validFile = true
      end
      #######################################

      if(!validFile)
        flash[:notice] = "You must choose a valid photo file. Valid image formats include: jpeg, jpg and png."
        redirect '/upload';
      else

        tmpfile = params[:file][:tempfile]

        # If there is no title entered Flickr will add in the last part of the :tempfile value which looks like crap.
        # Here is my solution.
        title = ""
        if(params[:title] == "")
          arr = params[:file][:filename].split(".")
          title = arr[0]
        else
          title = params[:title]
        end


        # upload the file
        photoID = @flickr.upload_photo tmpfile, :title => title, :description => (params[:description] + ""), :tags => (session['visitor_id'] + " " + session['app_id']), :is_public => 0, :hidden => 0

        #This is a pre-production call that should not be used in production code. Used only for testing outside of Rollbase
        # photoID = flickr.upload_photo tmpfile, :title => title, :description => (params[:description] + ""), :is_public => 0, :hidden => 0

        if photoID.to_i > 0
          flash[:notice] = "Photo Uploaded Successfully."
          redirect "/viewphotos/1"
        else
          flash[:notice] = "Oops, something went wrong. Please try again."
          redirect "/upload"
        end
      end
    end
  end
end
