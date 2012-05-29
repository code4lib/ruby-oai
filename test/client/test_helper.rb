if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

require 'oai'
require 'test/unit'

require File.dirname(__FILE__) + '/helpers/provider'
require File.dirname(__FILE__) + '/helpers/test_wrapper'
