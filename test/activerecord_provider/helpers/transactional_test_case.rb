class TransactionalTestCase < Test::Unit::TestCase

  def run(result, &block)
    # Handle the default "you have no tests" test if it turns up
    return if @method_name.to_s == "default_test"
    ActiveRecord::Base.transaction do
      load_fixtures
      result = super(result, &block)
      raise ActiveRecord::Rollback
    end
    result
  end

  protected

  def load_fixtures
    fixtures = YAML.load_file(
      File.join(File.dirname(__FILE__), '..', 'fixtures', 'dc.yml')
    )
    disable_logging do
      fixtures.keys.sort.each do |key|
        DCField.create(fixtures[key])
      end
    end
  end

  def disable_logging
    logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    yield
    ActiveRecord::Base.logger = logger
  end

end