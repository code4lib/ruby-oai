if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end
require 'oai'
require 'test/unit'

require File.dirname(__FILE__) + '/models'
include OAI

class SimpleProvider < Provider::Base
  repository_name 'Test Provider'
  record_prefix 'oai:test'
  source_model SimpleModel.new
end

class BigProvider < Provider::Base
  repository_name 'Another Provider'
  record_prefix 'oai:test'
  source_model BigModel.new
end

class TokenProvider < Provider::Base
  repository_name 'Token Provider'
  record_prefix 'oai:test'
  source_model BigModel.new(25)
end

class MappedProvider < Provider::Base
  repository_name 'Mapped Provider'
  record_prefix 'oai:test'
  source_model MappedModel.new
end

class ComplexProvider < Provider::Base
  repository_name 'Complex Provider'
  repository_url 'http://localhost'
  record_prefix 'oai:test'
  source_model ComplexModel.new(100)
end

class DescribedProvider < Provider::Base
  repository_name 'Described PRovider'
  repository_url 'http://localhost'
  record_prefix 'oai:test'
  source_model SimpleModel.new
  sample_id '13900'
  extra_description "<my_custom_xml />"
end
