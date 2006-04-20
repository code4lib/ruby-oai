module OAI
  
  # bundles up information about a set retrieved during a 
  # ListSets request
  
  class Set
    include OAI::XPath
    attr_accessor :name, :spec, :description

    def initialize(element)
      @name = xpath(element, './/setName')
      @spec = xpath(element, './/setSpec')
      @description = xpath_first(element, './/setDescription')
    end

    def to_s
      "#{@name} [#{@spec}]"
    end
  end
end
