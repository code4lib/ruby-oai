require 'test_helper_harvester'

class HarvestTest < Test::Unit::TestCase
  ONE_HOUR = 3600
  EARLIEST_FIXTURE = "1998-05-02T04:00:00Z"
  LATEST_FIXTURE = "2005-12-25T05:00:00Z"
  def test_harvest
    until_value = Time.now.utc - ONE_HOUR
    config = OpenStruct.new(sites: { 'test' => { 'url' => 'http://localhost:3333/oai' }})
    OAI::Harvester::Harvest.new(config).start
    last = config.sites.dig('test', 'last')
    assert_kind_of Time, last
    assert last >= (until_value + ONE_HOUR), "#{last} < #{(until_value + ONE_HOUR)}"
  end

  def test_harvest_from_last
    from_value = Time.parse(LATEST_FIXTURE).utc
    now = Time.now.utc
    config = OpenStruct.new(sites: { 'test' => { 'url' => 'http://localhost:3333/oai' }})
    OAI::Harvester::Harvest.new(config, nil, from_value).start
    last = config.sites.dig('test', 'last')
    assert last >= now, "#{last} < #{now}"
  end

  def test_harvest_after_last
    from_value = Time.parse(LATEST_FIXTURE).utc + 1
    config = OpenStruct.new(sites: { 'test' => { 'url' => 'http://localhost:3333/oai' }})
    OAI::Harvester::Harvest.new(config, nil, from_value).start
    last = config.sites.dig('test', 'last')
    assert_kind_of NilClass, last
  end
end

