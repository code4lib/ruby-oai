require 'test/unit'
require File.dirname(__FILE__) + '/../lib/oai'

class Record
  attr_accessor :id, :titles, :creator, :tags, :sets, :updated_at
  
  def initialize(id, titles, creator, tags, sets)
    @id = id;
    @titles = titles
    @creator = creator
    @tags = tags
    @sets = sets
    @updated_at = Time.new.utc
  end
  
  # Override Object.id
  def id
    @id
  end
  
  def in_set(spec)
    @sets.each { |set| return true if set.spec == spec }
    false
  end
  
end

class OneSet < OAI::Set
  
  def initialize
    @name = "Test Set"
    @spec = "A"
    @description = "A long winded description of this set."
  end
  
end

class TwoSet < OAI::Set

  def initialize
    @name = "Not so test Set"
    @spec = "A:B"
    @description = "A short winded description of this set."
  end
  
end

class SimpleModel
  include OAI::Model
  
  RECORDS = [
    Record.new(1, ['title 1', 'title 2'], 'creator', ['tag 1', 'tag 2'], [OneSet.new]),
    Record.new(2, ['title 3', 'title 4'], 'creator', ['tag 3', 'tag 4'], [OneSet.new]),
    Record.new(3, ['title 5', 'title 6'], 'creator', ['tag 5', 'tag 6'], [OneSet.new]),
    Record.new(4, ['title 7', 'title 8'], 'creator', ['tag 9', 'tag 8'], [OneSet.new, TwoSet.new]),
    Record.new(5, ['title 9', 'title 10'], 'creator', ['tag 9', 'tag 10'], [OneSet.new, TwoSet.new]),
    ]
    
  class << self
    def oai_earliest
      Time.parse("2006-10-31T00:00:00Z")
    end
    
    def oai_sets
      [OneSet.new, TwoSet.new]
    end
    
    def oai_find(selector, opts = {})
      if selector == :all
        if opts[:set]
          return RECORDS.select { |rec| rec.in_set(opts[:set]) }
        else
          return RECORDS
        end
      else
        RECORDS.each do |record|
          return record if record.id.to_s == selector
        end
      end
    end
  end
end

class MappedModel < SimpleModel

  def self.map_oai_dc
    {:title => :creator, :creator => :titles, :subject => :tags}
  end

end

