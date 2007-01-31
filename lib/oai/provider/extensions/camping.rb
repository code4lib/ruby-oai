require 'oai'

module OAI
  module Does
    module Camping
  
      def self.included(mod)
        instance_eval(%{module ::#{mod}::Controllers
          class Oai
            def get
              @headers['Content-Type'] = 'text/xml'
              provider = OAI::Provider::Base.new
              provider.process_request(@input.merge(:url => "http:"+URL(Oai).to_s))
            end
          end
        end
        })
      end
      
    end
  end
end
