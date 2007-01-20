require 'active_record'

module OAI
  
  class ActiveRecordWrapper < OAI::Model
    
    attr_reader :model, :timestamp_field
    
    def initialize(model, options={})
      @model = model
      @timestamp_field = options.delete(:timestamp_field) || 'updated_at'
      @limit = options.delete(:limit)
      
      unless options.empty?
        raise ArgumentException.new(
          "Unsupported options [#{options.join(', ')}]"
        )
      end
    end
    
    def earliest
      model.find(:first, 
        :order => "#{timestamp_field} asc").send(timestamp_field)
    end
    
    def latest
      model.find(:first, 
        :order => "#{timestamp_field} desc").send(timestamp_field)
    end
    
    def sets
      model.sets if model.respond_to?(:sets)
    end
    
    def find(selector, options={})
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
      else # end of result set
        model.find(:all, :conditions => token_conditions(base_token), 
          :limit => @limit, :offset => offset)
      end
    end
    
    # select a subset of the result set, and return it with a
    # resumption token to get the next subset
    def select_partial(token, offset)
      PartialResult.new(
        model.find(:all, 
          :conditions => token_conditions(token),
          :limit => @limit, 
          :offset => offset * @limit),
        ResumptionToken.new("#{token}:#{offset+1}")
      )
    end
    
    # build a sql conditions statement from the content
    # of a resumption token
    def token_conditions(token)
      sql_conditions extract_conditions_from_token(token)
    end
    
    # build a sql conditions statement from an OAI options hash
    def sql_conditions(opts)
      sql = []
      sql << "#{timestamp_field} >= ?" << "#{timestamp_field} <= ?" 
      sql << "set = ?" if opts[:set]

      esc_values = [sql.join(" AND ")]
      esc_values << opts[:from] << opts[:until]
      esc_values << opts[:set] if opts[:set]
      return esc_values
    end
    
  end
end
