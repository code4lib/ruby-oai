# External dependencies
require 'active_support'
require 'builder'
require 'chronic'

if not defined?(OAI::Const::VERBS)
  # Shared stuff
  
  require 'oai/exception'
  require 'oai/constants'
  require 'oai/helpers'
  require 'oai/xpath'
  require 'oai/metadata_format'
  require 'oai/set'
end

require 'oai/metadata_format/oai_dc'

# Localize requires so user can select a subset of functionality
libs = %w{model}

libs.each { |lib| require "oai/provider/#{lib}" }

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
# * No resumption tokens
# * Doesn't validate metadata
# * No deletion support
# * Many others I can't think of right now. :-)
#
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
# # these verbs require a working model
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
module OAI

  class Provider
    include Helpers
    
    AVAILABLE_FORMATS = { 'oai_dc' => OAI::Metadata::OaiDc }

    class << self
      attr_accessor :options

      def model(value)
        self.options ||={}
        self.options[:model] = value
      end

      def register_metadata_format(format)
        AVAILABLE_FORMATS[format.prefix] = format
      end
      
    end
    
    OAI::Const::PROVIDER_DEFAULTS.keys.each do |field|
       class_eval %{
         def self.#{field}(value)
           self.options ||={}
           self.options[:#{field}] = value
         end
       }
    end

    def initialize
      if self.class.options
        @config = OAI::Const::PROVIDER_DEFAULTS.merge(self.class.options)
      else
        @config = OAI::Const::PROVIDER_DEFAULTS
      end
      @model = @config[:model]
    end
    
    def identify
      process_verb 'Identify'
    end

    def list_metadata_formats
      process_verb 'ListMetadataFormats'
    end
    
    def list_sets(opts = {})
      process_verb 'ListSets', opts
    end
    
    def get_record(id, opts = {})
      process_verb 'GetRecord', opts.merge(:identifier => id)
    end
    
    def list_identifiers(opts = {})
      process_verb 'ListIdentifiers', opts
    end

    def list_records(opts = {})
      process_verb 'ListRecords', opts
    end
    
    # xml_response = process_verb('ListRecords', :from => 'October', 
    #   :until => 'November') # thanks Chronic!
    #
    # If you are implementing a web interface using process_verb is the
    # preferred way.  See extensions/camping.rb
    def process_verb(verb = nil, opts = {})
      header do
        begin
          # Allow the request to pass in a url
          @url = opts['url'] ? opts.delete('url') : @config[:url]
          
          echo_params(verb, opts)
          @opts = validate_options(verb, opts)

          # Rubify the verb for calling method
          call = verb.gsub(/[A-Z]/) {|m| "_#{m.downcase}"}.sub(/^\_/,'')
          send("#{call}_response")
          
        rescue
          if $!.respond_to?(:code)
            @xml.error $!.to_s, :code => $!.code
          else
            raise $!
          end
        end
      end
    end
    
    private
    
    def identify_response
      @xml.Identify do
        @xml.repositoryName @config[:name]
        @xml.baseURL @url
        @xml.protocolVersion 2.0
        @config[:email].to_a.each do |email|
          @xml.adminEmail email
        end
        @xml.earliestDatestamp earliest
        @xml.deleteRecord @config[:delete]
        @xml.granularity @config[:granularity]
      end
    end
    
    def list_sets_response
      raise OAI::SetException.new unless @model && @model.oai_sets
      @xml.ListSets do |ls|
        @model.oai_sets.each do |ms|
          @xml.set do |set|
            @xml.setSpec ms.spec
            @xml.setName ms.name
            @xml.setDescription(ms.description) if ms.respond_to?(:description)
          end
        end
      end
    end
    
    def list_metadata_formats_response
      @xml.ListMetadataFormats do 
        AVAILABLE_FORMATS.each_pair do |key, format|
          @xml.metadataFormat do 
            @xml.metadataPrefix format.send(:prefix)
            @xml.schema format.send(:schema)
            @xml.metadataNamespace format.send(:namespace)
          end
        end
      end
    end
    
    def list_identifiers_response
      unless supported_format? @opts[:metadata_prefix]
        raise OAI::FormatException.new
      end

      records = find :all

      raise OAI::NoMatchException.new if records.nil? || records.empty?

      @xml.ListIdentifiers do
        records.each do |record|
          metadata_header record
        end
      end
    end
    
    def get_record_response
      unless supported_format? @opts[:metadata_prefix]
        raise OAI::FormatException.new
      end
      
      rec = @opts[:identifier].gsub("#{@config[:prefix]}/", "")

      record = find rec

      raise OAI::IdException.new unless record

      @xml.GetRecord do
        @xml.record do 
          metadata_header record
          metadata record
        end
      end
    end
    
    def list_records_response
      unless supported_format? @opts[:metadata_prefix]
        raise OAI::FormatException.new
      end

      records = find :all

      raise OAI::NoMatchException.new if records.nil? || records.empty?

      @xml.ListRecords do
        records.each do |record|
          @xml.record do 
            metadata_header record
            metadata record
          end
        end  
      end  
    end
    
    def find(selector)
      return nil unless @model
      
      # Try oai finder methods first
      begin
        return @model.oai_find(selector, @opts)
      rescue NoMethodError
        begin
          # Try an ActiveRecord finder call
          return @model.find(selector, build_scope_hash)
        rescue 
        end
      end
      nil
    end
    
    def earliest
      return DateTime.new unless @model
      
      # Try oai finder methods first
      begin
        return @model.oai_earliest
      rescue NoMethodError
        begin
          # Try an ActiveRecord finder call
          return @model.find(:first, :order => "updated_at asc").updated_at
        rescue 
        end
      end
      nil
    end

    def sets
      return nil unless @model
      
      # Try oai finder methods first
      begin
        return @model.oai_sets
      rescue NoMethodError
      end
      nil
    end
      
    # emit record header
    def metadata_header(record)
      @xml.header do 
        @xml.identifier "#{@config[:prefix]}/#{record.id}"
        @xml.datestamp record.updated_at.utc.xmlschema
        record.sets.each do |set|
          @xml.setSpec set.spec
        end if record.respond_to?(:sets)
      end
    end


    # metadata - core routine for delivering metadata records
    #
    def metadata(record)
      if record.respond_to?("to_#{@opts[:metadata_prefix]}")
        @xml.metadata do
          str = record.send("to_#{@opts[:metadata_prefix]}")
          # Strip off the xml header if we got one.
          str.sub!(/<\?xml.*?\?>/, '')
          @xml << str
        end
      else
        map = @model.respond_to?("map_#{@opts[:metadata_prefix]}") ? 
          @model.send("map_#{@opts[:metadata_prefix]}") : {}

        mdformat = AVAILABLE_FORMATS[@opts[:metadata_prefix]]
        @xml.metadata do
          mdformat.header(@xml) do 
            mdformat.fields.each do |field|
              set = value_for(field, record, map)
              set.each do |mdv|
                @xml.tag! "#{mdformat.element_ns}:#{field}", mdv
              end
            end
          end
        end
      end
    end

    # We try a bunch of different methods to get the data from the model.
    #
    # 1) See if the model will hand us the entire record in the requested
    #    format.  Example:  if the model defines 'to_oai_dc' we call that
    #    method and append the result to the xml stream.
    # 2) Check if the model defines a field mapping for the field of 
    #    interest.
    # 3) Try calling the pluralized name method on the model.
    # 4) Try calling the singular name method on the model, if it's not a 
    #    reserved word. 
    def value_for(field, record, map)
      if map.keys.include?(field.intern)
          value = record.send(map[field.intern])
          if value.kind_of?(String)
            return [value]
          end
          return value.to_a 
      end
    
      begin # Plural value
        return record.send(field.pluralize).to_a 
      rescue 
        unless OAI::Const::RESERVED_WORDS.include?(field)
          begin # Singular value
            return [record.send(field)]
          rescue
            return []
          end
        end
      end
      []
    end
    
    def supported_format?(prefix)
      AVAILABLE_FORMATS.include?(prefix)
    end

  end
  
end