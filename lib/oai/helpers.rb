module OAI
  module Helpers
    
    # Output the OAI-PMH header
    def header
      @xml = Builder::XmlMarkup.new
      @xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
      @xml.tag!('OAI-PMH',
        'xmlns' => "http://www.openarchives.org/OAI/2.0/",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xsi:schemaLocation' => %{http://www.openarchives.org/OAI/2.0/
          http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd}) do 
        @xml.responseDate Time.now.utc.xmlschema
        yield
      end
    end

    # Echo the request parameters back to the client. See spec.
    def echo_params(verb, opts)
      @xml.request(@url, {:verb => verb}.merge(opts))
    end
  
    def build_active_record_conditions
      sql = []
      sql << "updated_at >= ?" if @opts[:from]
      sql << "updated_at <= ?" if @opts[:until]
      sql << "set = ?" if @opts[:set]
      
      esc_values = [sql.join(" AND ")]
      esc_values << @opts[:from] if @opts[:from]
      esc_values << @opts[:until] if @opts[:until]
      esc_values << @opts[:set] if @opts[:set]
    end

    # Use of Chronic here is mostly for human interactions.  It's
    # nice to be able to say '?verb=ListRecords&from=October&until=November'
    def parse_date(dt_string)
      # Oddly Chronic doesn't parse an UTC encoded datetime.  
      # Luckily Time does
      dt = Chronic.parse(dt_string) || Time.parse(dt_string)
      dt.utc.xmlschema
    end
  
    # Massage the standard OAI options to make them a bit more palatable.
    def validate_options(verb, opts = {})
      raise OAI::VerbException.new unless Const::VERBS.keys.include?(verb)

      return {} if opts.nil?
      
      # Not sure if this check is really even required, the user will still
      # recieve an error, and consult the docs.
      raise OAI::Exception.new("Bad options") unless opts.respond_to?(:keys)

      realopts = {}
      # Internalize the hash
      opts.keys.each do |key|
        realopts[key.to_s.gsub(/([A-Z])/, '_\1').downcase.intern] = opts.delete(key)
      end
      
      return realopts if is_resumption?(realopts)
      
      # add in a default metadataPrefix if none exists
      if(Const::VERBS[verb].include?(:metadata_prefix))
        realopts[:metadata_prefix] ||= 'oai_dc'
      end

      # check for any bad options
      unless (realopts.keys - OAI::Const::VERBS[verb]).empty?
        raise OAI::ArgumentException.new
      end
      realopts
    end
    
    def is_resumption?(opts)
      if opts.keys.include?(:resumption_token) 
        return true if 1 == opts.keys.size
        raise OAI::ArgumentException.new
      end
    end
    
    # Convert our internal representations back into standard OAI options
    def externalize(value)
      value.to_s.gsub(/_[a-z]/) { |m| m.sub("_", '').capitalize }
    end

  
  end
end
