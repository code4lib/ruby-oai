module OAI

  module Const
    # OAI defines six verbs with various allowable options.
    VERBS = {
      'Identify' => [],
      'ListMetadataFormats' => [],
      'ListSets' => [:resumption_token],  # unused currently
      'GetRecord' => [:identifier, :from, :until, :set, :metadata_prefix],
      'ListIdentifiers' => [:from, :until, :set, :metadata_prefix, :resumption_token],
      'ListRecords' => [:from, :until, :set, :metadata_prefix, :resumption_token]
    }.freeze
    
    RESERVED_WORDS = %w{type id}
    
    module DELETE
      NO = 0
      TRANSIENT = 1
      PERSISTENT = 2
    end
        
  end
  
end
