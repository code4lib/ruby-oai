module OAI::Metadata
  
  class MetadataFormat
    include Singleton
    
    attr_accessor :prefix, :schema, :namespace, :element_namespace, :fields
    
    def encode(model, record)
      if record.respond_to?("to_#{prefix}")
        record.send("to_#{prefix}")
      else
        xml = Builder::XmlMarkup.new
        map = model.respond_to?("map_#{prefix}") ? model.send("map_#{prefix}") : {}
          xml.tag!("#{prefix}:#{element_namespace}", header_specification) do
            fields.each do |field|
              values = value_for(field, record, map)
              values.each do |value|
                xml.tag! "#{element_namespace}:#{field}", value
              end
            end
          end
        xml.target!
      end
    end

    private

    # We try a bunch of different methods to get the data from the model.
    #
    # 1) See if the model will hand us the entire record in the requested
    #    format.  Example:  if the model defines 'to_oai_dc' we call that
    #    method and append the result to the xml stream.
    # 2) Check if the model defines a field mapping for the field of 
    #    interest.
    # 3) Try calling the pluralized name method on the model.
    # 4) Try calling the singular name method on the model
    def value_for(field, record, map)
      method = map[field] ? map[field].to_s : field.to_s
      
      methods = record.public_methods(false)
      if methods.include?(method.pluralize)
        record.send method.pluralize
      elsif methods.include?(method)
        record.send method
      else
        []
      end
    end

    def header_specification
      raise NotImplementedError.new
    end

  end
  
end

Dir.glob(File.dirname(__FILE__) + '/metadata_format/*.rb').each {|lib| require lib}
