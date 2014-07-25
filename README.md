flickr-sinatra-app
==================

Web Application written using the Ruby Sinatra Framework to allow users to CRUD Flickr Images using the Flickr API


##Installation Instructions

1. clone the repository onto your local machine with ```Shell git clone ```



##Portal install instructions

1. Create the js and css files on the portal (you can find the templates in flickrModule) make them hosted files.
2. Create the Edit page (which is actually a view page) on the applicants portal, style it and make sure it
has the target element that the js file you added is going to use to load the app.
3. Go to the header and footer of the applicant portal and add in three new entries to the portal pages hash,
the first will be the new "edit" page you created a little while ago and the other two are copies of the view
and review request pages. Add in your edit page to the pagination template at the bottom of the footer, and
then include the script and stylesheet files in the header or footer.
4. Add in a section to both request view pages where the user can view their photos, again make sure they
have the target section the js is going to use.
5. Tell me if I missed anything.
6. Enjoy.
