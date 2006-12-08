module OAI

  module Const
    # OAI defines six verbs with various allowable options.
    VERBS = {
      'Identify' => [],
      'ListMetadataFormats' => [],
      'ListSets' => [:token],
      'GetRecord' => [:identifier, :from, :until, :set, :metadata_prefix],
      'ListIdentifiers' => [:from, :until, :set, :metadata_prefix, :resumption_token],
      'ListRecords' => [:from, :until, :set, :metadata_prefix, :resumption_token]
      }.freeze
      
    # Common to many data sources, and sadly also a method on object.
    RESERVED_WORDS = %{type}.freeze
    
    # Default configuration of a repository
    PROVIDER_DEFAULTS = {  
      :name => 'Open Archives Initiative Data Provider',
      :url => 'unknown',
      :prefix => 'oai:localhost',
      :email => 'nobody@localhost',
      :deletes => 'no',
      :granularity => 'YYYY-MM-DDThh:mm:ssZ',
      :paginator => nil
    }.freeze
  end
  
end
