require 'test/unit'
require 'rubygems'
require 'action_controller'
require 'action_controller/test_case'
require 'action_view'
require 'action_view/test_case'

RAILS_ROOT = File.dirname(__FILE__) unless defined? RAILS_ROOT
require File.dirname(__FILE__) + "/../lib/country_select"
