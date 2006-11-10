# = model.rb
#
# Copyright (C) 2006 William Groppe
#
# Will Groppe mailto: wfg@artstor.org
#
#
# Implementing a model from scratch requires overridding three methods from
# OaiPmh::Model
#
# * oai_earliest - should provide the earliest possible timestamp
# * oai_sets - if you want to support sets
# * oai_find(selector, opts) - selector can be either a record id, or :all for
# finding all matches.  opts is a hash of query parameters.  Valid parameters
# include :from, :until, :set, :token, and :prefix.  Any errors in the
# parameters should raise a OaiPmh::ArgumentException.
#
module OAI
  module Model
    
    def self.oai_earliest
      Time.now.utc
    end
    
    def self.oai_sets
      nil
    end
    
    def self.oai_find(selector, opts={})
      []
    end
    
  end
end