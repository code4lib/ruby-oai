require 'test_helper'

class UTF8Test < Test::Unit::TestCase
  
  def test_escaping_invalid_utf_8_characters
    client = OAI::Client.new 'http://localhost:3333/oai' #, :parser => 'libxml'
    invalid_utf_8 = [2, 3, 4, 104, 5, 101, 6, 108, 66897, 108, 66535, 111, 1114112, 33, 55234123, 33].pack("U*")
    assert_equal("hello!!", client.send(:strip_invalid_utf_8_chars, invalid_utf_8).gsub(/\?/, ''))
  end

end
