require 'test/unit'
require File.dirname(__FILE__) + '/../lib/oai'

class Record
  attr_accessor :id, :titles, :creator, :tags, :sets, :updated_at, :deleted
  
  def initialize(id, titles, creator, tags, sets, deleted)
    @id = id;
    @titles = titles
    @creator = creator
    @tags = tags
    @sets = sets
    @deleted = deleted
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
    Record.new(1, ['title 1', 'title 2'], 'creator', ['tag 1', 'tag 2'], [OneSet.new], false),
    Record.new(2, ['title 3', 'title 4'], 'creator', ['tag 3', 'tag 4'], [OneSet.new], false),
    Record.new(3, ['title 5', 'title 6'], 'creator', ['tag 5', 'tag 6'], [OneSet.new], false),
    Record.new(4, ['title 7', 'title 8'], 'creator', ['tag 9', 'tag 8'], [OneSet.new, TwoSet.new], false),
    Record.new(5, ['title 9', 'title 10'], 'creator', ['tag 9', 'tag 10'], [OneSet.new, TwoSet.new], false),
    Record.new(6, ['title 11', 'title 12'], 'creator', ['tag 11', 'tag 12'], [OneSet.new], true),
    Record.new(7, ['title 13', 'title 14'], 'creator', ['tag 13', 'tag 14'], [OneSet.new], true),
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

