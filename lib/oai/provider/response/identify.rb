module OAI::Provider::Response
  
  class Identify < Base
    
    def to_xml
      response do |r|
        r.Identify do
          r.repositoryName provider.name
          r.baseURL provider.url
          r.protocolVersion 2.0
          provider.email.each do |address|
            r.adminEmail address
          end if provider.email
          r.earliestDatestamp provider.model.earliest
          r.deleteRecord word_for_delete(provider.delete_support)
          r.granularity provider.granularity
        end
      end
    end
    
    private
    
    def word_for_delete(delete_support)
      case delete_support
      when OAI::Const::DELETE::NO then 'no'
      when OAI::Const::DELETE::TRANSIENT then 'transient'
      when OAI::Const::DELETE::PERSISTENT then 'persistent'
      end
    end

  end
  
end
  