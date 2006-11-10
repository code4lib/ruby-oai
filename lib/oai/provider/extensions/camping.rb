require 'oai'

module OAI
  module Goes
    module Camping
  
      def self.included(mod)
        instance_eval(%{module ::#{mod}::Controllers
          class Oai
            def get
              @headers['Content-Type'] = 'text/xml'
              provider = OAI::Provider.new
              provider.process_verb(@input.delete('verb'), @input.merge(:url => "http:"+URL(Oai).to_s))
            end
          end
        end
        })
      end
      
    end
  end
end
