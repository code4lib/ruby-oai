require 'test/unit'
require File.dirname(__FILE__) + '/../lib/oai'

class Record
  attr_accessor :id, :titles, :creator, :tags, :sets, :updated_at, :deleted
  
  def initialize(id, 
      titles = 'title', 
      creator = 'creator', 
      tags = 'tag', 
      sets = [OneSet.new], 
      deleted = false,
      updated_at = Time.new.utc)
      
    @id = id;
    @titles = titles
    @creator = creator
    @tags = tags
    @sets = sets
    @deleted = deleted
    @updated_at = updated_at
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
      Time.parse("2000-11-30T00:00:00Z")
    end
    
    def oai_sets
      [OneSet.new, TwoSet.new]
    end
    
    def oai_find(selector, opts = {})
      if selector == :all
        recs = findall(opts[:set])

        recs.each do |r|
          recs.delete(r) if opts[:from] && opts[:from] >= r.updated_at
          recs.delete(r) if opts[:until] && opts[:until] <= r.updated_at
        end
        
        return recs
      else
        RECORDS.each do |record|
          return record if record.id.to_s == selector
        end
      end
    end
    
    private 
    
    def findall(set = nil)
      return RECORDS unless set
      RECORDS.select { |rec| rec.in_set(set) }
    end
    
  end
end

class MappedModel < SimpleModel

  def self.map_oai_dc
    {:title => :creator, :creator => :titles, :subject => :tags}
  end

end

class BigModel < SimpleModel
  include OAI::Model
  
  RECORDS = []
    
  class << self
    def oai_earliest
      Time.parse("2000-09-01T00:00:00Z")
    end
    
    def oai_sets
      [OneSet.new, TwoSet.new]
    end
    
    def oai_find(selector, opts = {})
      if selector == :all
        RECORDS.select do |rec|
          ((opts[:set].nil? || rec.in_set) && 
          (opts[:from].nil? || rec.updated_at > opts[:from]) &&
          (opts[:until].nil? || rec.updated_at < opts[:until]))
        end
      else
        RECORDS.each do |record|
          return record if record.id.to_s == selector
        end
      end
    end
    
  end
  
  october = Chronic.parse("October 2 2000")
  november = Chronic.parse("November 2 2000")
  december = Chronic.parse("December 2 2000")
  january = Chronic.parse("January 2 2001")
  february = Chronic.parse("February 2 2001")
  
  100.times do |id| 
    rec = Record.new(id)
    rec.updated_at = october
    RECORDS << rec
  end
  
  (101..200).each do |id|
    rec = Record.new(id)
    rec.updated_at = november
    RECORDS << rec
  end
    
  (201..300).each do |id|
    rec = Record.new(id)
    rec.updated_at = december
    RECORDS << rec
  end

  (301..400).each do |id|
    rec = Record.new(id)
    rec.updated_at = january
    RECORDS << rec
  end

  (401..500).each do |id|
    rec = Record.new(id)
    rec.updated_at = february
    RECORDS << rec
  end
  
end
