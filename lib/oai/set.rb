module OAI
  
  # bundles up information about a set retrieved during a 
  # ListSets request
  
  class Set
    include OAI::XPath
    attr_accessor :name, :spec, :description

    def self.parse(element)
      set = self.new
      set.name = set.xpath(element, './/setName')
      set.spec = set.xpath(element, './/setSpec')
      set.description = set.xpath_first(element, './/setDescription')
      set
    end
    
    def to_s
      "#{@name} [#{@spec}]"
    end
  end
end
