require 'test_helper_client'

class UTF8Test < Test::Unit::TestCase
  def client
    @client ||= OAI::Client.new 'http://localhost:3333/oai'
  end

  def test_escaping_invalid_utf_8_characters
    invalid_utf_8 = [2, 3, 4, 104, 5, 101, 6, 108, 66897, 108, 66535, 111, 1114112, 33, 55234123, 33].pack("U*")
    invalid_utf_8 = invalid_utf_8.force_encoding("binary") if invalid_utf_8.respond_to? :force_encoding
    assert_equal("hello!!", client.send(:strip_invalid_utf_8_chars, invalid_utf_8).gsub(/\?/, ''))
  end

  def test_unescaped_ampersand_content_correction
    src = '<test>Frankie & Johnny <character>&#9829;</character></test>'
    expected = '<test>Frankie &amp; Johnny <character>&#9829;</character></test>'
    assert_equal(expected, client.sanitize_xml(src))
  end
end
