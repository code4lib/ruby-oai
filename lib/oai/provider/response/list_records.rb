module OAI::Provider::Response

  class ListRecords < RecordResponse
    required_parameters :metadata_prefix
    
    def valid?
      super && matching_granularity?
    end
    
    def matching_granularity?
      if options[:from].nil? == false && options[:until].nil? == false && options[:from].class.name != options[:until].class.name
        raise OAI::ArgumentException.new, "The 'from' and 'until' options specified must have the same granularity"
      else
        true
      end
    end

    def to_xml
      result = provider.model.find(:all, options)
      # result may be an array of records, or a partial result
      records = result.respond_to?(:records) ? result.records : result

      raise OAI::NoMatchException.new if records.nil? or records.empty?

      response do |r|
        r.ListRecords do
          records.each do |rec|
            r.record do
              header_for rec
              data_for rec unless deleted?(rec)
              about_for rec unless deleted?(rec)
            end
          end

          # append resumption token for getting next group of records
          if result.respond_to?(:token)
            r.target! << result.token.to_xml
          end

        end
      end
    end

  end

end

