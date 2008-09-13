require 'singleton'

module OAI::Provider::Metadata
  # == Metadata Base Class
  #
  # MetadataFormat is the base class from which all other format classes 
  # should inherit.  Format classes provide mapping of record fields into XML.
  #
  # * prefix - contains the metadata_prefix used to select the format
  # * schema - location of the xml schema
  # * namespace - location of the namespace document
  # * element_namespace - the namespace portion of the XML elements
  # * fields - list of fields in this metadata format
  #
  # See OAI::Metadata::DublinCore for an example
  #
  class Format
    include Singleton
    
    attr_accessor :prefix, :schema, :namespace, :element_namespace, :fields
    
    # Provided a model, and a record belonging to that model this method
    # will return an xml represention of the record.  This is the method
    # that should be extended if you need to create more complex xml
    # representations.
    def encode(model, record)
      if record.respond_to?("to_#{prefix}")
        record.send("to_#{prefix}")
      else
        xml = Builder::XmlMarkup.new
        map = model.respond_to?("map_#{prefix}") ? model.send("map_#{prefix}") : {}
          xml.tag!("#{prefix}:#{element_namespace}", header_specification) do
            fields.each do |field|
              values = value_for(field, record, map)
              if values.respond_to?(:each)
                values.each do |value|
                  xml.tag! "#{element_namespace}:#{field}", value
                end
              else
                xml.tag! "#{element_namespace}:#{field}", values
              end
            end
          end
        xml.target!
      end
    end

    private

    # We try a bunch of different methods to get the data from the model.
    #
    # 1.  Check if the model defines a field mapping for the field of 
    #     interest.
    # 2.  Try calling the pluralized name method on the model.
    # 3.  Try calling the singular name method on the model
    def value_for(field, record, map)
      method = map[field] ? map[field].to_s : field.to_s 
     
      if record.respond_to?(pluralize(method))
        record.send pluralize(method)
      elsif record.respond_to?(method)
        # at this point, this function will throw a dep. error because of the call to type -- a reserved work
        # in ruby
        record.send method
      else
        []
      end
    end

    # Subclasses must override
    def header_specification
      raise NotImplementedError.new
    end
    
    # Shamelessly lifted form ActiveSupport.  Thanks Rails community!
    def pluralize(word)
      # Use ActiveSupports pluralization if it's available.
      return word.pluralize if word.respond_to?(:pluralize)
      
      # Otherwise use our own simple pluralization rules.
      result = word.to_s.dup
      
      # Uncountable words
      return result if %w(equipment information rice money species series fish sheep).include?(result)
      
      # Irregular words
      { 'person' => 'people', 'man' => 'men', 'child' => 'children', 'sex' => 'sexes', 
        'move' => 'moves', 'cow' => 'kine' }.each { |k,v| return v if word == k }
      
      rules.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
      result
    end
    
    def rules
      [
        [/$/, 's'],
        [/s$/i, 's'],
        [/(ax|test)is$/i, '\1es'],
        [/(octop|vir)us$/i, '\1i'],
        [/(alias|status)$/i, '\1es'],
        [/(bu)s$/i, '\1ses'],
        [/(buffal|tomat)o$/i, '\1oes'],
        [/([ti])um$/i, '\1a'],
        [/sis$/i, 'ses'],
        [/(?:([^f])fe|([lr])f)$/i, '\1\2ves'],
        [/(hive)$/i, '\1s'],
        [/([^aeiouy]|qu)y$/i, '\1ies'],
        [/(x|ch|ss|sh)$/i, '\1es'],
        [/(matr|vert|ind)(?:ix|ex)$/i, '\1ices'],
        [/([m|l])ouse$/i, '\1ice'],
        [/^(ox)$/i, '\1en'],
        [/(quiz)$/i, '\1zes']
      ]
    end

  end
  
end

Dir.glob(File.dirname(__FILE__) + '/metadata_format/*.rb').each {|lib| require lib}
