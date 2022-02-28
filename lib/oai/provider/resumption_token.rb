require 'time'
require File.dirname(__FILE__) + "/partial_result"

module OAI::Provider
  # = OAI::Provider::ResumptionToken
  #
  # The ResumptionToken class forms the basis of paging query results.  It
  # provides several helper methods for dealing with resumption tokens.
  #
  # OAI-PMH spec does not specify anything about resumptionToken format, they can
  # be purely opaque tokens.
  #
  # Our implementation however encodes everything needed to construct the next page
  # inside the resumption token.
  #
  # == The 'last' component: offset or ID/pk to resume from
  #
  # The `#last` component is an offset or ID to resume from. In the case of it being
  # an ID to resume from, this assumes that ID's are sortable and results are returned
  # in ID order, so that the 'last' ID can be used as the place to resume from.
  #
  # Originally it was assumed that #last was always an integer, but since existing
  # implementations (like ActiveRecordWrapper) used it as an ID, and identifiers and
  # primary keys are _not_ always integers (can be UUID etc), we have expanded to allow
  # any string value.
  #
  # However, for backwards compatibility #last always returns an integer (sometimes 0 if
  # actual last component is not an integer), and #last_str returns the full string version.
  # Trying to change #last itself to be string broke a lot of existing code in this gem
  # in mysterious ways.
  #
  # Also beware that in some cases the value 0/"0" seems to be a special value used
  # to signify some special case. A lot of "code archeology" going on here after significant
  # period of no maintenance to this gem.
  class ResumptionToken
    attr_reader :prefix, :set, :from, :until, :last, :last_str, :expiration, :total

    # parses a token string and returns a ResumptionToken
    def self.parse(token_string)
      begin
        options = {}
        matches = /(.+):([^ :]+)$/.match(token_string)
        options[:last] = matches.captures[1]

        parts = matches.captures[0].split('.')
        options[:metadata_prefix] = parts.shift
        parts.each do |part|
          case part
          when /^s/
            options[:set] = part.sub(/^s\(/, '').sub(/\)$/, '')
          when /^f/
            options[:from] = Time.parse(part.sub(/^f\(/, '').sub(/\)$/, '')).localtime
          when /^u/
            options[:until] = Time.parse(part.sub(/^u\(/, '').sub(/\)$/, '')).localtime
          end
        end
        self.new(options)
      rescue => err
        raise OAI::ResumptionTokenException.new
      end
    end

    # extracts the metadata prefix from a token string
    def self.extract_format(token_string)
      return token_string.split('.')[0]
    end

    def initialize(options, expiration = nil, total = nil)
      @prefix = options[:metadata_prefix]
      @set = options[:set]
      self.last = options[:last]
      @from = options[:from] if options[:from]
      @until = options[:until] if options[:until]
      @expiration = expiration if expiration
      @total = total if total
    end

    # convenience method for setting the offset of the next set of results
    def next(last)
      self.last = last
      self
    end

    def ==(other)
      prefix == other.prefix and set == other.set and from == other.from and
        self.until == other.until and last == other.last and
        expiration == other.expiration and total == other.total
    end

    # output an xml resumption token
    def to_xml
      xml = Builder::XmlMarkup.new
      xml.resumptionToken(encode_conditions, hash_of_attributes)
      xml.target!
    end

    # return a hash containing just the model selection parameters
    def to_conditions_hash
      conditions = {:metadata_prefix => self.prefix }
      conditions[:set] = self.set if self.set
      conditions[:from] = self.from if self.from
      conditions[:until] = self.until if self.until
      conditions
    end

    # return the a string representation of the token minus the offset/ID
    #
    # Q: Why does it eliminate the offset/id "last" on the end? Doesn't fully
    #    represent state without it, which is confusing. Not sure, but
    #    other code seems to rely on it, tests break if not.
    def to_s
      encode_conditions.gsub(/:\w+?$/, '')
    end

    private

    # take care of our logic to store an integer and a str version, for backwards
    # compat where it was assumed to be an integer, as well as supporting string.
    def last=(value)
      @last = value.to_i
      @last_str = value.to_s
    end

    def encode_conditions
      encoded_token = @prefix.to_s.dup
      encoded_token << ".s(#{set})" if set
      encoded_token << ".f(#{self.from.utc.xmlschema})" if self.from
      encoded_token << ".u(#{self.until.utc.xmlschema})" if self.until
      encoded_token << ":#{last_str}"
    end

    def hash_of_attributes
      attributes = {}
      attributes[:completeListSize] = self.total if self.total
      attributes[:expirationDate] = self.expiration.utc.xmlschema if self.expiration
      attributes
    end

  end

end
