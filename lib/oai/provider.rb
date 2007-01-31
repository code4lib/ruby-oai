# External dependencies
require 'active_support'
require 'builder'
require 'chronic'

if not defined?(OAI::Const::VERBS)
  # Shared stuff
  require 'oai/exception'
  require 'oai/constants'
  require 'oai/xpath'
  require 'oai/set'
end

%w{ response metadata_format resumption_token model partial_result
    response/record_response response/identify response/get_record
    response/list_identifiers response/list_records 
    response/list_metadata_formats response/list_sets response/error
  }.each { |lib| require File.dirname(__FILE__) + "/provider/#{lib}" }

# = provider.rb
#
# Copyright (C) 2006 William Groppe
#
# Will Groppe mailto:wfg@artstor.org
#
# Open Archives Initiative - Protocol for Metadata Harvesting see 
# http://www.openarchives.org/ 
#
# === Features
# * Easily setup a simple repository
# * Simple integration with ActiveRecord
# * Dublin Core metadata format included
# * Easily add addition metadata formats
# * Adaptable to any data source
#
#
# === Current shortcomings
# * Doesn't validate metadata
# * Many others I can't think of right now. :-)
#
# === ActiveRecord integration
#
# To successfully use ActiveRecord as a OAI PMH datasource the database table
# should include an updated_at column so that updates to the table are 
# tracked by ActiveRecord.  This provides much of the base functionality for
# selecting update periods.
#
# To understand how the data is extracted from the AR model it's best to just
# go thru the logic:
#
# Does the model respond to 'to_{prefix}'?  Where prefix is the
# metadata prefix.  If it does then just include the response from
# the model.  So if you want to provide custom or complex metadata you can 
# simply define a 'to_{prefix}' method on your model.
# 
# Example:
#
#  class Record < ActiveRecord::Base
#
#    def to_oai_dc
#      xml = Builder::XmlMarkup.new
#      xml.tag!('oai_dc:dc',
#        'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
#        'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
#        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
#        'xsi:schemaLocation' => 
#          %{http://www.openarchives.org/OAI/2.0/oai_dc/ 
#          http://www.openarchives.org/OAI/2.0/oai_dc.xsd}) do
#
#          xml.oai_dc :title, title
#          xml.oai_dc :subject, subject
#      end
#      xml.to_s
#    end
#
#  end
#
# If the model doesn't define a 'to_{prefix}' then start iterating thru
# the defined metadata fields.
#
# Grab a mapping if one exists by trying to call 'map_{prefix}'.
#
# Now do the iteration and try calling methods on the model that match
# the field names, or the mapped field names.
#
# So with Dublin Core we end up with the following:
#
# 1. Check for 'title' mapped to a different method.
# 2. Call model.titles - try plural
# 3. Call model.title - try singular last
#
# Extremely contrived Blog example:
#
#  class Post < ActiveRecord::Base
#    def map_oai_dc
#      {:subject => :tags, 
#       :description => :text, 
#       :creator => :user, 
#       :contibutor => :comments}
#    end
#  end
#
# === Supporting custom metadata
#
# See Oai::Metadata for details.
# 
# == Examples
#
# === Sub classing a provider
#
#  class MyProvider < Oai::Provider
#    name 'My little OAI provider'
#    url 'http://localhost/provider'
#    prefix 'oai:localhost'
#    email 'root@localhost'             # String or Array
#    deletes 'no'                       # future versions will support deletes
#    granularity 'YYYY-MM-DDThh:mm:ssZ' # update resolution
#    model MyModel                      # Class to get data from
#  end
#
# # Now use it
#
#  provider = MyProvider.new
#  provider.identify
#  provider.list_sets
#  provider.list_metadata_formats
#  # these verbs require a working model
#  provider.list_identifiers
#  provider.list_records
#  provider.get_record('oai:localhost/1')
#
#
# === Configuring the default provider
#
#  class Oai::Provider
#    name 'My little OAI Provider'
#    url 'http://localhost/provider'
#    prefix 'oai:localhost'
#    email 'root@localhost'             # String or Array
#    deletes 'no'                       # future versions will support deletes
#    granularity 'YYYY-MM-DDThh:mm:ssZ' # update resolution
#    model MyModel                      # Class to get data from
#  end
#
# 
module OAI::Provider

  class Base
    include OAI::Provider
    
    class << self
      attr_reader :formats
      attr_accessor :name, :url, :prefix, :email, :delete_support, :granularity, :model

      def register_format(format)
        @formats ||= {}
        @formats[format.prefix] = format
      end
      
      def format_supported?(prefix)
        @formats.keys.include?(prefix)
      end
      
      def format(prefix)
        @formats[prefix]
      end
      
      def inherited(klass)
        self.instance_variables.each do |iv|
          klass.instance_variable_set(iv, self.instance_variable_get(iv))
        end
      end

      alias_method :repository_name,    :name=
      alias_method :repository_url,     :url=
      alias_method :record_prefix,      :prefix=
      alias_method :admin_email,        :email=
      alias_method :deletion_support,   :delete_support=  
      alias_method :update_granularity, :granularity=     
      alias_method :source_model,       :model=
      
    end

    # Default configuration of a repository
    Base.repository_name 'Open Archives Initiative Data Provider'
    Base.repository_url 'unknown'
    Base.record_prefix 'oai:localhost'
    Base.admin_email 'nobody@localhost'
    Base.deletion_support OAI::Const::DELETE::TRANSIENT
    Base.update_granularity 'YYYY-MM-DDThh:mm:ssZ'

    Base.register_format(OAI::Metadata::DublinCore.instance)
    
    def identify(options = {})
      Response::Identify.new(self.class, options).to_xml
    end

    def list_sets(options = {})
      Response::ListSets.new(self.class, options).to_xml
    end
    
    def list_metadata_formats(options = {})
      Response::ListMetadataFormats.new(self.class, options).to_xml
    end
    
    def list_identifiers(options = {})
      Response::ListIdentifiers.new(self.class, options).to_xml
    end
    
    def list_records(options = {})
      Response::ListRecords.new(self.class, options).to_xml
    end
    
    def get_record(options = {})
      Response::GetRecord.new(self.class, options).to_xml
    end
    
    # xml_response = process_verb('ListRecords', :from => 'October', 
    #   :until => 'November') # thanks Chronic!
    #
    # If you are implementing a web interface using process_verb is the
    # preferred way.  See extensions/camping.rb
    def process_request(params = {})
      begin

        # Allow the request to pass in a url
        self.class.url = params['url'] ? params.delete('url') : self.class.url
          
        verb = params.delete('verb') || params.delete(:verb)
        
        unless verb and OAI::Const::VERBS.keys.include?(verb)
          raise OAI::VerbException.new
        end
          
        send(methodize(verb), params) 

      rescue => err
        if err.respond_to?(:code)
          Response::Error.new(self.class, err).to_xml
        else
          raise err
        end
      end
    end
    
    def methodize(verb)
      verb.gsub(/[A-Z]/) {|m| "_#{m.downcase}"}.sub(/^\_/,'')
    end
    
  end
  
end