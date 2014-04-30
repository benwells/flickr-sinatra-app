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
  get '/init/:api_key/:shared_secret/:access_token/:access_secret/:visitor_id/:app_id/:mode' do

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
    if params[:mode] == 'e'
      redirect '/list';
    elsif params[:mode] == 'v'
      redirect '/viewphotos';
    end
  end

  get '/viewphotos' do
    # Get all photos from flickr account
    # The search method automatically sorts by uploaded at desc.
    @userPhotos = getUserPhotos()
    @appPhotos = getAppPhotos()

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


  ##############################################################################
  # The setup crap for the index page.
  get '/list' do
    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']
    @appPhotos = getAppPhotos()
    @userPhotos = getUserPhotos()

    @totalPhotos = @appPhotos.length + @userPhotos.length

    # This is giving me an error.
    # # Give all user photos that intersect with appPhotos a class attribute of 'selected'
    # @appPhotos.each do |photo|
    #   if (@appPhotos.include? photo)
    #     photo['class'] = 'selected'
    #   end
    # end

    haml :index
  end


  # Edit single photo info
  ##############################################################################
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

    redirect '/list';
  end


  # This takes a list of comma seperated photo ids and the tag you would like to remove.
  ##############################################################################
  get '/detach/:photoids' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    photoId = params[:photoids].to_s
    tag = session['app_id'].to_s

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
          if tags[count].to_s == tag
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
    redirect '/viewphotos';
  end


  #delete photo
  ##############################################################################
  get '/delete/:photoid' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    photoId = params[:photoid]
    photoId = photoId.to_i

    flickr.photos.delete(:photo_id => photoId)

    flash[:notice] = "The photo has been deleted."
    redirect '/list';
  end

  # Note to self, this is fine.
  ################################
  get '/attach/:photoids' do

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    photoIds = params[:photoids].to_s

    if params[:photoids] != '0'
      photosToAttach = photoIds.split(',')
      photosToAttach.each do |ids|

        flickr.photos.addTags(:photo_id => ids.to_i, :tags => session['app_id'].to_s)
      end
    end

    redirect '/viewphotos'
  end

  #upload new photo
  ##############################################################################
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
          redirect "/list"
        else
          flash[:notice] = "Oops, something went wrong. Please try again."
          redirect "/upload"
        end
      end
    end
  end

  def getUserPhotos

    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    # App photos is all of the photos... Logical right?
    @allPhotos = @flickr.photos.search(:user_id => "me", :tags => "#{session['app_id'].to_s}" + "," + "#{session['visitor_id'].to_s}", :tag_mode => "ALL", :privacy_filter => '5', :per_page => '50',:page => '1')

    # Building the list of info for all of the applications photos because the search method does not return exactly what we need.
    # This array should be parallel to the allPhotos array so that we can retrive the proper photos.
    tmp = @allPhotos['photo']
    @photoIds = tmp
    @photoInfo = []
    @userPhotos = []
    tags = []
    tagValues = []
    count = 0

    # Building a list of the information we need to filter the photos.
    # The main difference between appPhotos and allPhotos is the amount of
    # information included in each of the lists. appPhotos has tags included
    # as well as most of the other info we need to display.
    while count < @photoIds.length do
      tmp = flickr.photos.getInfo :photo_id => (@photoIds[count]['id'])
      @photoInfo.insert(-1, tmp);
      count += 1
    end

    # Getting all of the tag values and putting them into their own arrays.
    count = 0
    while count < @photoInfo.length do
      @photoInfo[count]['tags'].each do |tag|
        tags.insert(-1, tag['_content'])
      end
      tagValues.insert(-1, tags)
      tags = []
      count += 1
    end

    # Here we are filtering based on if the photo has only the visitor id.
    # If they have more than that, they are not included. So, the only photos that are
    # included here are the one that will go into the module on the index page.
    count = 0
    flag = 0

    while count < tagValues.length do
      tagValues[count].each do |val|

        if val == session['visitor_id'].to_s
          flag += 1
        else
          if val == session['app_id'].to_s
            flag -= 1
          end
        end
      end

      if flag == 1
        @userPhotos.insert(-1, @photoInfo[count]);
      end

      flag = 0
      count += 1
    end
    return @userPhotos
  end #################################################### End of getUserPhotos.

  def getAppPhotos
    FlickRaw.api_key = session['api_key']
    FlickRaw.shared_secret = session['shared_secret']
    flickr.access_token = session['access_token']
    flickr.access_secret = session['access_secret']

    # App photos is all of the photos... Logical right?
    @allPhotos = @flickr.photos.search(:user_id => "me", :tags => "#{session['app_id'].to_s}" + "," + "#{session['visitor_id'].to_s}", :tag_mode => "ALL", :privacy_filter => '5', :per_page => '50',:page => '1')

    # Building the list of info for all of the applications photos because the search method does not return exactly what we need.
    # This array should be parallel to the allPhotos array so that we can retrive the proper photos.
    tmp = @allPhotos['photo']
    @photoIds = tmp
    @photoInfo = []
    @appPhotos = []
    tags = []
    tagValues = []
    count = 0

    # Building a list of the information we need to filter the photos.
    # The main difference between appPhotos and allPhotos is the amount of
    # information included in each of the lists. appPhotos has tags included
    # as well as most of the other info we need to display.
    while count < @photoIds.length do
      tmp = flickr.photos.getInfo :photo_id => (@photoIds[count]['id'])
      @photoInfo.insert(-1, tmp);
      count += 1
    end

    # Getting all of the tag values and putting them into their own arrays.
    count = 0
    while count < @photoInfo.length do
      @photoInfo[count]['tags'].each do |tag|
        tags.insert(-1, tag['_content'])
      end
      tagValues.insert(-1, tags)
      tags = []
      count += 1
    end

    # Here we are filtering based on if the photo has both the visitor id and the app id.
    # If they have more (or less) than that, they are not included.
    # So, the only photos that are included here are the one that will go into
    # the "Slick" component on the index page.
    count = 0
    flag = 0

    while count < tagValues.length do
      tagValues[count].each do |val|
        if val == session['visitor_id'].to_s || val == session['app_id'].to_s
          flag += 1
        end
      end

      if flag == 2
        @appPhotos.insert(-1, @photoInfo[count]);
      end

      flag = 0
      count += 1
    end

    return @appPhotos
  end ##################################################### End of getAppPhotos.

end
