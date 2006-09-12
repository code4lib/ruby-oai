class ExceptionTest < Test::Unit::TestCase

  def test_http_error
    client = OAI::Client.new 'http://www.example.com'
    begin
      client.identify
      flunk 'did not throw expected exception'
    rescue OAI::Exception => e
      assert_match /^HTTP level error/, e.to_s, 'include error message'
    end
  end

  def test_xml_error
    client = OAI::Client.new 'http://www.yahoo.com'
    begin 
      client.identify
    rescue OAI::Exception => e
      assert_match /response not well formed XML/, e.to_s, 'xml error'
    end
  end
end
