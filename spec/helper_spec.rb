require File.expand_path '../../lib/helpers.rb', __FILE__
require File.expand_path '../test_setup', __FILE__


class MyTest < MiniTest::Unit::TestCase
  include Helpers

  def test_merge_services
    assert_equal merge_services([{'serviceUid' => 'abc123'}], [{'serviceUid' => 'abc123'}]).length, 1
    assert_equal merge_services([{'serviceUid' => 'abc123'}], [{'serviceUid' => 'xyz456'}]).length, 2
  end

  def test_clean_tmp
    require 'fileutils'
    FileUtils.mkdir_p 'tmp/test'
    FileUtils.touch 'tmp/test/alice.json', :mtime => Time.now - 60*60*24*100
    clean_tmp
    refute File.exist? 'tmp/test/alice.json'
  end

  def test_load_date_returns_date
    assert_equal load_date.class, Date
    assert_equal load_date(nil), Date.today
    assert_equal load_date('2015-08-12'), Date.parse('2015-08-12')
  end

  def test_load_date_loads_services
    load_date('2015-08-29')
    assert_equal @previous_day_services.length, 2
    assert_equal @current_day_services.length, 2
  end

  def test_get_rtt_workings
    assert get_rtt_workings['services'].is_a? Array
    assert_equal get_rtt_workings(Date.parse('2015-08-29'))['services'].length, 1
    assert_equal get_rtt_workings(Date.parse('2015-08-29'), 'LDS')['services'].length, 1
    assert_equal get_rtt_workings(Date.parse('2015-08-29'), 'LDS', 'departures')['services'].length, 1
    assert_equal get_rtt_workings(Date.parse('2015-08-29'), 'LDS', 'arrivals')['services'].length, 1

    assert_equal get_rtt_workings(Date.parse('2015-08-28'))['services'].length, 1

  end
end
