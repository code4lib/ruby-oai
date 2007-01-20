require 'oai'
require 'active_record'
require "config/connection.rb"
require 'oai/provider/model/activerecord_wrapper'
require 'oai/provider/model/activerecord_caching_wrapper'

Dir.glob(File.dirname(__FILE__) + "/../models/*.rb").each do |lib|
  require lib
end

class ARProvider < OAI::Provider
  name 'ActiveRecord Based Provider'
  prefix 'oai:test'
  url 'http://localhost'
  model OAI::ActiveRecordWrapper.new(DCField)
end

class SimpleResumptionProvider < OAI::Provider
  name 'ActiveRecord Resumption Provider'
  prefix 'oai:test'
  url 'http://localhost'
  model OAI::ActiveRecordWrapper.new(DCField, :limit => 25)
end

class CachingResumptionProvider < OAI::Provider
  name 'ActiveRecord Caching Resumption Provider'
  prefix 'oai:test'
  url 'http://localhost'
  model OAI::ActiveRecordCachingWrapper.new(DCField, :limit => 25)
end
  

class ARLoader
  def self.load
    fixtures = YAML.load_file(
      File.join(File.dirname(__FILE__), '..', 'fixtures', 'dc.yml')
    )
    fixtures.keys.sort.each do |key|
      DCField.create(fixtures[key])
    end
  end
  
  def self.unload
    DCField.delete_all
  end
end
