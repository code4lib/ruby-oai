require 'active_support'
require 'builder'
require 'chronic'

if not defined?(OAI::Const::VERBS)
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
  
if defined?(ActiveRecord)
  require File.dirname(__FILE__) + "/provider/model/activerecord_wrapper"
  require File.dirname(__FILE__) + "/provider/model/activerecord_caching_wrapper"
end

module OAI::Provider
  # = provider
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
  # === Current shortcomings
  # * Doesn't validate metadata
  # * Many others I can't think of right now. :-)
  #
  # == Usage
  #
  # To create a functional provider either subclass Provider::Base, or reconfigure
  # the defaults.
  # 
  # === Sub classing a provider
  #
  #  class MyProvider < Oai::Provider
  #    repository_name 'My little OAI provider'
  #    repository_url  'http://localhost/provider'
  #    record_prefix 'oai:localhost'
  #    admin_email 'root@localhost'             # String or Array
  #    source_model MyModel.new
  #  end
  #
  # === Configuring the default provider
  #
  #  class Oai::Provider::Base
  #    repository_name 'My little OAI Provider'
  #    repository_url 'http://localhost/provider'
  #    record_prefix 'oai:localhost'
  #    admin_email 'root@localhost'
  #    source_model MyModel.new
  #  end
  #
  # == Integrating with frameworks
  #
  # === Camping
  #
  # In the Models module of your camping application post model definition:
  # 
  #   class CampingProvider < OAI::Provider::Base
  #     repository_name 'Camping Test OAI Repository'
  #     source_model ActiveRecordWrapper.new(YOUR_ACTIVE_RECORD_MODEL)
  #   end
  #
  # In the Controllers module:
  #
  #   class Oai
  #     def get
  #       @headers['Content-Type'] = 'text/xml'
  #       provider = Models::CampingProvider.new
  #       provider.process_request(@input.merge(:url => "http:"+URL(Oai).to_s))
  #     end
  #   end
  #
  # The provider will be available at "/oai"
  #
  # === Rails
  #
  # 
  #
  # === Supporting custom metadata
  #
  # See Oai::Metadata for details.
  # 
  # == Examples
  #
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

      protected 
      
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
    
    # Equivalent to '&verb=Identify', returns information about the repository
    def identify(options = {})
      Response::Identify.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=ListSets', returns a list of sets that are supported
    # by the repository or an error if sets are not supported.
    def list_sets(options = {})
      Response::ListSets.new(self.class, options).to_xml
    end
    
    # Equivalent to '&verb=ListMetadataFormats', returns a list of metadata formats
    # supported by the repository.
    def list_metadata_formats(options = {})
      Response::ListMetadataFormats.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=ListIdentifiers', returns a list of record headers that 
    # meet the supplied criteria.
    def list_identifiers(options = {})
      Response::ListIdentifiers.new(self.class, options).to_xml
    end
    
    # Equivalent to '&verb=ListRecords', returns a list of records that meet the 
    # supplied criteria.
    def list_records(options = {})
      Response::ListRecords.new(self.class, options).to_xml
    end
    
    # Equivalent to '&verb=GetRecord', returns a record matching the required
    # :identifier option 
    def get_record(options = {})
      Response::GetRecord.new(self.class, options).to_xml
    end
    
    #  xml_response = process_verb('ListRecords', :from => 'October', 
    #    :until => 'November') # thanks Chronic!
    #
    # If you are implementing a web interface using process_request is the
    # preferred way.
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
    
    # Convert valid OAI-PMH verbs into ruby method calls
    def methodize(verb)
      verb.gsub(/[A-Z]/) {|m| "_#{m.downcase}"}.sub(/^\_/,'')
    end
    
  end
  
end