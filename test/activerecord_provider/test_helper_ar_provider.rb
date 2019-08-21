require 'rubygems'

if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end
require 'test/unit'
require File.dirname(__FILE__) + '/config/connection'
require File.dirname(__FILE__) + '/helpers/providers'
require File.dirname(__FILE__) + '/helpers/set_provider'
require File.dirname(__FILE__) + '/helpers/transactional_test_case'
