module OAI::Provider::Response
  class ListMetadataFormats < RecordResponse
    valid_parameters :identifier
    
    def to_xml
      # Get a list of all the formats the provider understands.
      formats = provider.formats.values
      
      # if it's a doc-specific request
      if options.include?(:identifier)
        id = extract_identifier(options[:identifier])
        unless record = provider.model.find(id, options)
          raise OAI::IdException.new
        end
      
        # Remove any format that this particular record can't be provided in.
        formats.reject! { |f| !record_supports(record, f.prefix) }
      end
      response do |r|
        r.ListMetadataFormats do
          formats.each do |format|
            r.metadataFormat do 
              r.metadataPrefix format.prefix
              r.schema format.schema
              r.metadataNamespace format.namespace
            end
          end
        end
      end
    end
    
    def record_supports(record, prefix)
      prefix == 'oai_dc' or 
      record.respond_to?("to_#{prefix}") or
      record.respond_to?("map_#{prefix}")
    end
    
  end  
end
