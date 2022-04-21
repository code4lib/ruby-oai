require 'active_record'

module OAI::Provider
  # This class wraps an ActiveRecord model and delegates all of the record
  # selection/retrieval to the AR model.  It accepts options for specifying
  # the update timestamp field, a timeout, and a limit.  The limit option
  # is used for doing pagination with resumption tokens.  The
  # expiration timeout is ignored, since all necessary information is
  # encoded in the token.
  #
  class ActiveRecordWrapper < Model

    attr_reader :model, :timestamp_field, :identifier_field

    # If custom 'timestamp_field' is used, be aware this will be an ActiveRecord
    # attribute that we will limit on, so perhaps should be indexe appropriately.
    #
    # If custom `identifier_field` is used, be aware this will be an ActiveRecord
    # attribute that we will sort on, and use in WHERE clauses with `=` as well as
    # greater than/less than, so should be indexed appropriately.
    def initialize(model, options={})
      @model = model
      @timestamp_field = options.delete(:timestamp_field) || 'updated_at'
      @identifier_field = options.delete(:identifier_field) || model.primary_key || "id"
      @limit = options.delete(:limit) || 100

      unless options.empty?
        raise ArgumentError.new(
          "Unsupported options [#{options.keys.join(', ')}]"
        )
      end
    end

    def earliest
      earliest_obj = model.order("#{timestamp_field} asc").first
      earliest_obj.nil? ? Time.at(0) : earliest_obj.send(timestamp_field)
    end

    def latest
      latest_obj = model.order("#{timestamp_field} desc").first
      latest_obj.nil? ? Time.now : latest_obj.send(timestamp_field)
    end
    # A model class is expected to provide a method Model.sets that
    # returns all the sets the model supports.  See the
    # activerecord_provider tests for an example.
    def sets
      model.sets if model.respond_to?(:sets)
    end

    def find(selector, options={})
      find_scope = find_scope(options)
      return next_set(find_scope,
        options[:resumption_token]) if options[:resumption_token]
      conditions = sql_conditions(options)
      if :all == selector
        total = find_scope.where(conditions).count
        if @limit && total > @limit
          select_partial(find_scope,
            ResumptionToken.new(options.merge({:last => 0})))
        else
          find_scope.where(conditions)
        end
      else
        find_scope.where(conditions).find_by!(identifier_field => selector)
      end
    end

    def deleted?(record)
      if record.respond_to?(:deleted_at)
        return record.deleted_at
      elsif record.respond_to?(:deleted)
        return record.deleted
      end
      false
    end

    def respond_to?(m, *args)
      if m =~ /^map_/
        model.respond_to?(m, *args)
      else
        super
      end
    end

    def method_missing(m, *args, &block)
      if m =~ /^map_/
        model.send(m, *args, &block)
      else
        super
      end
    end

    protected

    def find_scope(options)
      return model unless options.key?(:set)

      # Find the set or return an empty scope
      set = find_set_by_spec(options[:set])
      return model.limit(0) if set.nil?

      # If the set has a backward relationship, we'll use it
      if set.class.respond_to?(:reflect_on_all_associations)
        set.class.reflect_on_all_associations.each do |assoc|
          return set.send(assoc.name) if assoc.klass == model
        end
      end

      # Search the attributes for 'set'
      if model.column_names.include?('set')
        # Scope using the set attribute as the spec
        model.where(set: options[:set])
      else
        # Default to empty set, as we've tried everything else
        model.none
      end
    end

    def find_set_by_spec(spec)
      if sets.class == ActiveRecord::Relation
        sets.find_by_spec(spec)
      else
        sets.detect {|set| set.spec == spec}
      end
    end

    # Request the next set in this sequence.
    def next_set(find_scope, token_string)
      raise OAI::ResumptionTokenException.new unless @limit

      token = ResumptionToken.parse(token_string)
      select_partial(find_scope, token)
    end

    # select a subset of the result set, and return it with a
    # resumption token to get the next subset
    def select_partial(find_scope, token)
      records = find_scope.where(token_conditions(token))
        .limit(@limit)
        .order("#{identifier_field} asc")
      raise OAI::ResumptionTokenException.new unless records

      total = find_scope.where(token_conditions(token)).count
      # token offset should be nil if this is the last set
      offset = (@limit >= total) ? nil : records.last.send(identifier_field)
      PartialResult.new(records, token.next(offset))
    end

    # build a sql conditions statement from the content
    # of a resumption token.  It is very important not to
    # miss any changes as records may change scope as the
    # harvest is in progress.  To avoid loosing any changes
    # the last 'id' of the previous set is used as the
    # filter to the next set.
    def token_conditions(token)
      last_id = token.last_str
      sql = sql_conditions token.to_conditions_hash

      return sql if "0" == last_id
      # Now add last id constraint
      sql.first << " AND #{identifier_field} > :id"
      sql.last[:id] = last_id

      return sql
    end

    # build a sql conditions statement from an OAI options hash
    def sql_conditions(opts)
      sql = []
      esc_values = {}
      if opts.has_key?(:from)
        sql << "#{timestamp_field} >= :from"
        esc_values[:from] = parse_to_local(opts[:from])
      end
      if opts.has_key?(:until)
        # Handle databases which store fractions of a second by rounding up
        sql << "#{timestamp_field} < :until"
        esc_values[:until] = parse_to_local(opts[:until]) { |t| t + 1 }
      end
      return [sql.join(" AND "), esc_values]
    end

    private

    def parse_to_local(time)
      time_obj = Time.parse(time.to_s)
      time_obj = yield(time_obj) if block_given?
      # Convert to same as DB - :local => :getlocal, :utc => :getutc

      if ActiveRecord::VERSION::MAJOR >= 7
        tzconv = "get#{ActiveRecord.default_timezone.to_s}".to_sym
      else
        tzconv = "get#{model.default_timezone.to_s}".to_sym
      end
      time_obj.send(tzconv).strftime("%Y-%m-%d %H:%M:%S")
    end

  end
end

