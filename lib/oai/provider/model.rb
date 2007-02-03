module OAI::Provider
  # = OAI::Provider::Model
  #
  # Model implementers should subclass OAI::Provider::Model and override 
  # Model#earliest, Model#latest, and Model#find.  Optionally Model#sets and
  # Model#deleted? can be used to support sets and record deletions.
  #
  # == Resumption Tokens
  #
  # == ActiveRecord Integration
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

  class Model
    attr_reader :timestamp_field
    
    def initialize(limit = nil, timestamp_field = 'updated_at')
      @limit = limit
      @timestamp_field = timestamp_field
    end

    # should return the earliest timestamp available from this model.
    def earliest
      raise NotImplementedError.new
    end
    
    # should return the latest timestamp available from this model.
    def latest
      raise NotImplementedError.new
    end
    
    def sets
      nil
    end
  
    # find is the core method of a model, it returns records from the model
    # bases on the parameters passed in.
    #
    # <tt>selector</tt> can be a singular id, or the symbol :all
    # <tt>options</tt> is a hash of options to be used to constrain the query.
    #
    # Valid options:
    # * :from => earliest timestamp to be included in the results
    # * :until => latest timestamp to be included in the results
    # * :set => the set from which to retrieve the results
    # * :metadata_prefix => type of metadata requested (this may be useful if 
    #                       not all records are available in all formats)
    def find(selector, options={})
      raise NotImplementedError.new
    end
    
    def deleted?
      false
    end
    
  end
  
end
