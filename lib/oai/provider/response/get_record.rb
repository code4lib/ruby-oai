module OAI::Provider::Response

  class GetRecord < RecordResponse
    required_parameters :identifier, :metadata_prefix

    def to_xml
      id = extract_identifier(options.delete(:identifier))
      unless record = provider.model.find(id, options)
        raise OAI::IdException.new
      end

      response do |r|
        r.GetRecord do
          r.record do
            header_for record
            data_for record unless deleted?(record)
            about_for record unless deleted?(record)
          end
        end
      end
    end

  end

end


