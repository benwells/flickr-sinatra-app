require 'rubygems'
require 'bundler'
Bundler.require

require './main'
# require 'newrelic_rpm'
# NewRelic::Agent.after_fork(:force_reconnect => true)

run FlickrApp
