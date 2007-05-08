module OAI::Provider::Response
  
  class ListIdentifiers < RecordResponse
    required_parameters :metadata_prefix
    
    def to_xml
      result = provider.model.find(:all, options)

      # result may be an array of records, or a partial result
      records = result.respond_to?(:records) ? result.records : result
      
      raise OAI::NoMatchException.new if records.nil? or records.empty?
      records.reject! { |r| !record_supports(r, options[:metadata_prefix]) }
      
      response do |r|
        r.ListIdentifiers do
          records.each do |rec|
            header_for rec
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