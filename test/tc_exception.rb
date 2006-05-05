class ExceptionTest < Test::Unit::TestCase

  def test_http_error
    client = OAI::Client.new 'http://www.example.com'
    begin
      client.identify
      flunk 'did not throw expected exception'
    rescue OAI::Exception => e
      assert_match /Connection refused/, e.to_s, 'include error message'
    end
  end

  def test_xml_error
    client = OAI::Client.new 'http://www.google.com'
    begin 
      client.identify
    rescue OAI::Exception => e
      assert_match /response not well formed XML/, e.to_s, 'xml error'
    end
  end

  # some oai providers have been known to respond with redirects!
  def test_redirect
    client = OAI::Client.new('http://citebase.eprints.org/cgi-bin/oai2')
    assert_nothing_thrown(client.get_record(
      :identifier => 'oai:arXiv.org:nlin/0101014'))
  end
end
