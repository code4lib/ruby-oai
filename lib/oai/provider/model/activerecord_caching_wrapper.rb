require 'active_record'

module OAI
  
  class OaiToken < ActiveRecord::Base
    has_many :entries, :class_name => 'OaiEntry', 
      :order => "record_id", :dependent => :destroy

    validates_uniqueness_of :token
    
    # Make sanitize_sql a public method so we can make use of it.
    public
     
    def self.sanitize_sql(*arg)
      super(*arg)
    end
    
    def new_record_before_save?
      @new_record_before_save
    end

  end

  class OaiEntry < ActiveRecord::Base
    belongs_to :oai_token

    validates_uniqueness_of :record_id, :scope => :oai_token
  end
    
  
  class ActiveRecordCachingWrapper < ActiveRecordWrapper
    
    attr_reader :model, :timestamp_field, :expire
    
    def initialize(model, options={})
      @expire = options.delete(:timeout) || 12.hours
      super(model, options)
    end
    
    def find(selector, options={})
      sweep_cache
      return next_set(token(options)) if token(options)

      constrain_from_until(options)
      conditions = sql_conditions(options)

      if :all == selector
        total = model.count conditions
        if @limit && total > @limit
          select_partial(generate_token(options), 0)
        else
          model.find(:all, :conditions => conditions)
        end
      else
        model.find(selector, :conditions => conditions)
      end
    end
  
    protected 
  
    def next_set(token)
      raise ResumptionTokenException.new unless @limit

      base_token, offset = extract_token_and_offset(token)
      total = model.count token_conditions(base_token)
  
      if offset * @limit + @limit < total
        select_partial(base_token, offset)
      else 
        select_partial(base_token, offset).records
      end
    end
  
    # select a subset of the result set, and return it with a
    # resumption token to get the next subset
    def select_partial(token, offset)
      if 0 == offset
        oaitoken = OaiToken.find_or_create_by_token(token)
        if oaitoken.new_record_before_save?
          OaiToken.connection.execute("insert into " +
            "#{OaiEntry.table_name} (oai_token_id, record_id) " +
            "select #{oaitoken.id}, id from #{model.table_name} where " +
            "#{OaiToken.sanitize_sql(token_conditions(token))}")
        end
      end
      
      oaitoken = OaiToken.find_by_token(token)
      
      raise ResumptionTokenException.new unless oaitoken

      PartialResult.new(
        hydrate_records(oaitoken.entries.find(:all, :limit => @limit, 
          :offset => offset * @limit)),
        ResumptionToken.new("#{token}:#{offset+1}", 
          expires_at(oaitoken.created_at))
      )
    end
    
    def sweep_cache
      OaiToken.destroy_all(["created_at < ?", Time.now - expire])
    end
    
    def hydrate_records(records)
      model.find(records.collect {|r| r.record_id })
    end
    
    private
    
    def expires_at(creation)
      created = Time.parse(creation.strftime("%Y-%m-%d %H:%M:%S"))
      created.utc + expire
    end

  end
end
