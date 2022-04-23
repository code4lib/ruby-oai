require 'test_helper_ar_provider'

class ActiveRecordWrapperTest < TransactionalTestCase
  def test_sql_conditions_from_date
    input = "2005-12-25"
    expected = input.dup
    sql_template, sql_opts = sql_conditions(from: input)
    assert_equal "updated_at >= :from", sql_template
    assert_equal expected, sql_opts[:from]
    sql_template, sql_opts = sql_conditions(from: Date.strptime(input, "%Y-%m-%d"))
    assert_equal "updated_at >= :from", sql_template
    assert_equal expected, sql_opts[:from]
  end

  def test_sql_conditions_from_time
    input = "2005-12-25T00:00:00Z"
    expected = "2005-12-25 00:00:00"
    sql_template, sql_opts = sql_conditions(from: input)
    assert_equal "updated_at >= :from", sql_template
    assert_equal expected, sql_opts[:from]
    sql_template, sql_opts = sql_conditions(from: Time.strptime(input, "%Y-%m-%dT%H:%M:%S%Z"))
    assert_equal "updated_at >= :from", sql_template
    assert_equal expected, sql_opts[:from]
  end

  def test_sql_conditions_until_date
    input = "2005-12-25"
    expected = "2005-12-26"
    sql_template, sql_opts = sql_conditions(until: input)
    assert_equal "updated_at < :until", sql_template
    assert_equal expected, sql_opts[:until]
    sql_template, sql_opts = sql_conditions(until: Date.strptime(input, "%Y-%m-%d"))
    assert_equal "updated_at < :until", sql_template
    assert_equal expected, sql_opts[:until]
  end

  def test_sql_conditions_until_time
    input = "2005-12-25T00:00:00Z"
    expected = "2005-12-25 00:00:01"
    sql_template, sql_opts = sql_conditions(until: input)
    assert_equal "updated_at < :until", sql_template
    assert_equal expected, sql_opts[:until]
    sql_template, sql_opts = sql_conditions(until: Time.strptime(input, "%Y-%m-%dT%H:%M:%S%Z"))
    assert_equal "updated_at < :until", sql_template
    assert_equal expected, sql_opts[:until]
  end

  def test_sql_conditions_both
    input = "2005-12-25"
    sql_template, sql_opts = sql_conditions(from: input, until: input)
    assert_equal "updated_at >= :from AND updated_at < :until", sql_template
  end

  def setup
    @wrapper = OAI::Provider::ActiveRecordWrapper.new(DCField)
  end

  def sql_conditions(opts)
    @wrapper.send :sql_conditions, opts
  end
end


