require 'test_helper'

class ProviderExceptions < Test::Unit::TestCase

  def setup
    @provider = ComplexProvider.new
  end

  def test_argument_exception
    assert_raise(OAI::ArgumentException) do
      @provider.identify(:identifier => 'invalid_arg')
    end
  end

  def test_resumption_token_exception
    assert_raise(OAI::ResumptionTokenException) do
      @provider.list_records(:resumption_token => 'aaadddd:1000')
    end
    assert_raise(OAI::ResumptionTokenException) do
      @provider.list_records(:resumption_token => 'oai_dc:1000')
    end
    assert_raise(OAI::ResumptionTokenException) do
      @provider.list_identifiers(:resumption_token => '..::!:.:!:')
    end
    assert_raise(OAI::ResumptionTokenException) do
      @provider.list_identifiers(:resumption_token => '\:\\:\/$%^&*!@#!:1')
    end
  end

  def test_bad_verb_raises_exception
    assert @provider.process_request(:verb => 'BadVerb') =~ /badVerb/
    assert @provider.process_request(:verb => '\a$#^%!@') =~ /badVerb/
    assert @provider.process_request(:verb => 'identity') =~ /badVerb/
    assert @provider.process_request(:verb => '!!\\$\$\.+') =~ /badVerb/
  end

  def test_bad_format_raises_exception
    assert_raise(OAI::FormatException) do
      @provider.get_record(:identifier => 'oai:test/1', :metadata_prefix => 'html')
    end
  end

  def test_missing_format_raises_exception
    assert_raise(OAI::ArgumentException) do
      @provider.list_records()
    end
    assert_raise(OAI::ArgumentException) do
      @provider.get_record(:identifier => 'oai:test/1')
    end
  end

  def test_bad_id_raises_exception
    badIdentifiers = [
      'oai:test/5000',
      'oai:test/-1',
      'oai:test/one',
      'oai:test/\\$1\1!']
    badIdentifiers.each do |id|
      assert_raise(OAI::IdException) do
        @provider.get_record(:identifier => id, :metadata_prefix => 'oai_dc')
      end
    end
  end

  def test_no_records_match_dates_that_are_out_of_range
    assert_raise(OAI::NoMatchException) do
      @provider.list_records(:metadata_prefix => 'oai_dc',
                             :from => Time.parse("November 2 2000"),
                             :until => Time.parse("November 1 2000"))
    end
  end

  def test_no_records_match_bad_set
    assert_raise(OAI::NoMatchException) do
      @provider.list_records(:metadata_prefix => 'oai_dc', :set => 'unknown')
    end
  end

end
