module OAI::Provider::Response

  class ListMetadataFormats < RecordResponse
    valid_parameters :identifier
    def to_xml
      # if it's a doc-specific request
      if (!options[:identifier].nil?) 
        
        id = extract_identifier(options[:identifier])
        unless record = provider.model.find(id, options)
          raise OAI::IdException.new
        end
        response do |r|
          r.ListMetadataFormats do 
            provider.model.available_formats(record).each do |prefix|
              format = provider.format(prefix)
              r.metadataFormat do 
                r.metadataPrefix format.prefix
                r.schema format.schema
                r.metadataNamespace format.namespace
              end
            end
          end
        end
      # otherwise it's a provider format request
      else 
        response do |r|
          r.ListMetadataFormats do 
            provider.formats.each do |key, format|
              r.metadataFormat do 
                r.metadataPrefix format.prefix
                r.schema format.schema
                r.metadataNamespace format.namespace
              end
            end
          end
        end
      end
    end
    def extract_identifier(id)
      id.sub("#{provider.prefix}/", '')
    end
    
  end  

end