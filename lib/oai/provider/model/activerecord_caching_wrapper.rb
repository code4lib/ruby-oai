require 'active_record'

module OAI::Provider

  # ActiveRecord model class in support of the caching wrapper.
  class OaiToken < ActiveRecord::Base
    has_many :entries, -> { order("record_id ASC") },
      :class_name => 'OaiEntry', :dependent => :destroy

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

  # ActiveRecord model class in support of the caching wrapper.
  class OaiEntry < ActiveRecord::Base
    belongs_to :oai_token

    validates_uniqueness_of :record_id, :scope => :oai_token
  end

  # This class wraps an ActiveRecord model and delegates all of the record
  # selection/retrieval to the AR model.  It accepts options for specifying
  # the update timestamp field, a timeout, and a limit.  The limit option
  # is used for doing pagination with resumption tokens.  The timeout is
  # used to expire old tokens from the cache.  Default timeout is 12 hours.
  #
  # The difference between ActiveRecordWrapper and this class is how the
  # pagination is accomplished.  ActiveRecordWrapper encodes all the
  # information in the token.  That approach should work 99% of the time.
  # If you have an extremely active respository you may want to consider
  # the caching wrapper.  The caching wrapper takes the entire result set
  # from a request and caches it in another database table, well tables
  # actually.  So the result returned to the client will always be
  # internally consistent.
  #
  class ActiveRecordCachingWrapper < ActiveRecordWrapper

    attr_reader :model, :timestamp_field, :expire

    def initialize(model, options={})
      @expire = options.delete(:timeout) || 12.hours
      super(model, options)
    end

    def find(selector, options={})
      sweep_cache
      return next_set(options[:resumption_token]) if options[:resumption_token]

      conditions = sql_conditions(options)

      if :all == selector
        total = model.where(conditions).count
        if @limit && total > @limit
          select_partial(
            ResumptionToken.new(options.merge({:last => 0})))
        else
          model.where(conditions)
        end
      else
        model.where(conditions).find(selector)
      end
    end

    protected

    def next_set(token_string)
      raise ResumptionTokenException.new unless @limit

      token = ResumptionToken.parse(token_string)
      select_partial(token)
    end

    # select a subset of the result set, and return it with a
    # resumption token to get the next subset
    def select_partial(token)
      oaitoken = OaiToken.find_by(token: token.to_s)

      if 0 == token.last && oaitoken.nil?
        oaitoken = OaiToken.create!(token: token.to_s)
        OaiToken.connection.execute("insert into " +
          "#{OaiEntry.table_name} (oai_token_id, record_id) " +
          "select #{oaitoken.id}, id from #{model.table_name} where " +
          "#{OaiToken.sanitize_sql(token_conditions(token))}")
      end

      raise ResumptionTokenException.new unless oaitoken

      total = model.where(token_conditions(token)).count
      # token offset should be nil if this is the last set
      offset = (token.last * @limit + @limit >= total) ? nil : token.last + 1
      PartialResult.new(
        hydrate_records(
          oaitoken.entries.limit(@limit).offset(token.last * @limit)),
        token.next(offset)
      )
    end

    def sweep_cache
      OaiToken.where(["created_at < ?", Time.now - expire]).destroy_all
    end

    def hydrate_records(records)
      model.find(records.collect {|r| r.record_id })
    end

    def token_conditions(token)
      sql_conditions token.to_conditions_hash
    end

    private

    def expires_at(creation)
      created = Time.parse(creation.strftime("%Y-%m-%d %H:%M:%S"))
      created.utc + expire
    end

  end
end
