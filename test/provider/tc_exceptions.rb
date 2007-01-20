class ProviderExceptions < Test::Unit::TestCase

  def setup
    @provider = ComplexProvider.new
  end

  def test_resumption_token_exception
    assert @provider.list_records(:resumption_token => 'aaadddd:1000') =~
      /badResumptionToken/
    assert @provider.list_records(:resumption_token => 'oai_dc:1000') =~
      /badResumptionToken/
    assert @provider.list_identifiers(:resumption_token => '..::!:.:!:') =~
      /badResumptionToken/
    assert @provider.list_identifiers(
      :resumption_token => '\:\\:\/$%^&*!@#!:1') =~
        /badResumptionToken/
  end
  
  def test_verb_exception
    assert @provider.process_verb('BadVerb') =~ /badVerb/
    assert @provider.process_verb('\a$#^%!@') =~ /badVerb/
    assert @provider.process_verb('identity') =~ /badVerb/
    assert @provider.process_verb('!!\\$\$\.+') =~ /badVerb/
  end
  
  def test_format_exception
    assert @provider.get_record('oai:test/1', 
      :metadata_prefix => 'html') =~ /cannotDisseminateFormat/
  end
  
  def test_id_exception
    assert @provider.get_record('oai:test/5000') =~ /idDoesNotExist/
    assert @provider.get_record('oai:test/-1') =~ /idDoesNotExist/
    assert @provider.get_record('oai:test/one') =~ /idDoesNotExist/
    assert @provider.get_record('oai:test/\\$1\1!') =~ /idDoesNotExist/
  end
  
  def test_no_match_exception
    assert @provider.list_records(
      :from => Chronic.parse("November 2 2000"), 
      :until => Chronic.parse("November 1 2000")
      ) =~ /noRecordsMatch/

    assert @provider.list_records(:set => 'unknown') =~ /noRecordsMatch/
  end
  
  def test_set_exception
  end
  
end
