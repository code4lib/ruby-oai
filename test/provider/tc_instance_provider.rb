require 'test_helper_provider'

class TestInstanceProvider < Test::Unit::TestCase

  # Prior to the commit introducing this code, the InstanceProvider#identify
  # method would instantiate a Response::Identify object, passing the
  # InstanceProvider class as the provider for the Response::Identify
  # instance. With the commit introducing this test, the
  # InstanceProvider#identify now passes the instance of InstanceProvider
  # to the instantiation of Response::Identify.
  #
  # Thus we can override, on an instance by instance basis, the behavior of a
  # response object.
  def test_instance_used_in_responses
    @url_path = "/stringy-mc-string-face"
    @instance_provider = InstanceProvider.new(:instance_based, @url_path)

    xml = @instance_provider.identify
    doc =  REXML::Document.new(xml)
    assert_equal "http://localhost#{@url_path}", doc.elements["OAI-PMH/Identify/baseURL"].text
  end

  def test_class_used_in_responses
    @url_path = "/stringy-mc-string-face"
    @instance_provider = InstanceProvider.new(:class_based, @url_path)

    xml = @instance_provider.identify
    doc =  REXML::Document.new(xml)
    assert_equal "http://localhost", doc.elements["OAI-PMH/Identify/baseURL"].text
  end

end
