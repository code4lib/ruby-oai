module OAI::Provider::Response
  class RecordResponse < Base
    def self.inherited(klass)
      klass.valid_parameters    :metadata_prefix, :from, :until, :set
      klass.default_parameters  :metadata_prefix => "oai_dc",
           :from => method(:default_from).to_proc,
           :until => method(:default_until).to_proc
    end

    def self.default_from(response)
      value = Time.parse(response.provider.model.earliest.to_s).utc
      if response.options[:until]
        u = parse_date(response.options[:until])
        value = value.to_date if u.is_a? Date
      end
      value
    end

    def self.default_until(response)
      value = Time.parse(response.provider.model.latest.to_s).utc
      if response.options[:from]
        f = parse_date(response.options[:from])
        value = value.to_date if f.is_a? Date
      end
      value
    end

    # emit record header
    def header_for(record)
      param = Hash.new
      param[:status] = 'deleted' if deleted?(record)
      @builder.header param do
        @builder.identifier identifier_for(record)
        @builder.datestamp timestamp_for(record)
        sets_for(record).each do |set|
          @builder.setSpec set.spec
        end
      end
    end
    # metadata - core routine for delivering metadata records
    #
    def data_for(record)
      @builder.metadata do
        @builder.target! << provider.format(requested_format).encode(provider.model, record)
      end
    end

    # about - core routine for delivering about records
    #
    def about_for(record)
      return unless provider.model.respond_to? :about

      about = provider.model.about(record)
      return if about.nil?

      unless about.is_a? Array
        about = [about]
      end

      about.each do |a|
        @builder.about do
          @builder.target! << a
        end
      end
    end

    private

    # Namespace syntax suggested in http://www.openarchives.org/OAI/2.0/guidelines-oai-identifier.htm
    def identifier_for(record)
      "#{provider.prefix}:#{record.send( provider.model.identifier_field )}"
    end

    def timestamp_for(record)
      record.send(provider.model.timestamp_field).utc.xmlschema
    end

    def sets_for(record)
      return [] unless record.respond_to?(:sets) and record.sets
      record.sets.respond_to?(:each) ? record.sets : [record.sets]
    end

    def requested_format
      format =
      if options[:metadata_prefix]
        options[:metadata_prefix]
      elsif options[:resumption_token]
        OAI::Provider::ResumptionToken.extract_format(options[:resumption_token])
      end
      raise OAI::FormatException.new unless provider.format_supported?(format)

      format
    end

    def deleted?(record)
      return record.deleted? if record.respond_to?(:deleted?)
      return record.deleted if record.respond_to?(:deleted)
      return record.deleted_at if record.respond_to?(:deleted_at)
      false
    end

  end
end
