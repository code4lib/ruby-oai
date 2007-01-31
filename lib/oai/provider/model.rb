# = model.rb
#
# Copyright (C) 2006 William Groppe
#
# Will Groppe mailto: wfg@artstor.org
#
#
# Implementing a model from scratch requires overridding two methods from
# OAI::Model
#
# * earliest - should provide the earliest possible timestamp
# * find(selector, opts) - selector can be either a record id, or :all for
# finding all matches.  opts is a hash of query parameters.  
# Valid parameters include:
#   :from => Time for beginning of selection
#   :until => Time for end of selection
#   :set => String for requested set
#   :prefix => String for metadata prefix
#
#  Any errors in the parameters should raise a OaiPmh::ArgumentException.
#
# Optional methods
#
# * sets - if you want to support sets
# * deleted? - if you want to support deletions
#
module OAI::Provider

  class Model
    include ResumptionHelpers
    
    attr_reader :timestamp_field
    
    def initialize(limit = nil, timestamp_field = 'updated_at')
      @limit = limit
      @timestamp_field = timestamp_field
    end
    
    def earliest
      raise NotImplementedError.new
    end
    
    def latest
      raise NotImplementedError.new
    end
    
    def sets
      nil
    end
  
    def find(selector, opts={})
      raise NotImplementedError.new
    end
    
    def deleted?
      false
    end
    
  end
  
end
