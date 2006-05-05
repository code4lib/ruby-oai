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
end
