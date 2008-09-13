module OAI::Provider::Response
  
  class Identify < Base
    
    def to_xml
      response do |r|
        r.Identify do
          r.repositoryName provider.name
          r.baseURL provider.url
          r.protocolVersion 2.0
          if provider.email and provider.email.respond_to?(:each)
            provider.email.each { |address| r.adminEmail address }
          else
            r.adminEmail provider.email.to_s
          end
          r.earliestDatestamp Time.parse(provider.model.earliest.to_s).utc.xmlschema
          r.deletedRecord provider.delete_support.to_s
          r.granularity provider.granularity
        end
      end
    end
    
  end
  
end
