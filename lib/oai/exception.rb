module OAI

  # Standard error responses for problems serving OAI content.  These
  # messages will be wrapped in an XML response to the client.

  class Exception < RuntimeError
    CODE = nil
    MESSAGE = nil

    attr_reader :code

    @@codes = {}

    def self.register_exception_code(code, exception_class)
      @@codes[code] = exception_class if exception_class.superclass == OAI::Exception
    end

    def self.for(message: nil, code: nil)
      @@codes.fetch(code, Exception).new(message)
    end

    def initialize(message = nil, code = nil)
      super(message || self.class::MESSAGE)
      @code = code || self.class::CODE
    end
  end

  class ArgumentException < Exception
    CODE = 'badArgument'
    MESSAGE = 'The request includes ' \
      'illegal arguments, is missing required arguments, includes a ' \
      'repeated argument, or values for arguments have an illegal syntax.'
    register_exception_code(CODE, self)
  end

  class VerbException < Exception
    CODE = 'badVerb'
    MESSAGE = 'Value of the verb argument is not a legal OAI-PMH '\
      'verb, the verb argument is missing, or the verb argument is repeated.'
    register_exception_code(CODE, self)
  end

  class FormatException < Exception
    CODE = 'cannotDisseminateFormat'
    MESSAGE = 'The metadata format identified by '\
        'the value given for the metadataPrefix argument is not supported '\
        'by the item or by the repository.'
    register_exception_code(CODE, self)
  end

  class IdException < Exception
    CODE = 'idDoesNotExist'
    MESSAGE = 'The value of the identifier argument is '\
        'unknown or illegal in this repository.'
    register_exception_code(CODE, self)
  end

  class NoMatchException < Exception
    CODE = 'noRecordsMatch'
    MESSAGE = 'The combination of the values of the from, '\
      'until, set and metadataPrefix arguments results in an empty list.'
    register_exception_code(CODE, self)
  end

  class MetadataFormatException < Exception
    CODE = 'noMetadataFormats'
    MESSAGE = 'There are no metadata formats available '\
        'for the specified item.'
    register_exception_code(CODE, self)
  end

  class SetException < Exception
    CODE = 'noSetHierarchy'
    MESSAGE = 'This repository does not support sets.'
    register_exception_code(CODE, self)
  end

  class ResumptionTokenException < Exception
    CODE = 'badResumptionToken'
    MESSAGE = 'The value of the resumptionToken argument is invalid or expired.'
    register_exception_code(CODE, self)
  end
end