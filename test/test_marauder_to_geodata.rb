require "minitest/autorun"
require "json"
require "nokogiri"
require_relative "../marauder_to_geodata"

class TestMarauderToGeoData < Minitest::Test
  def setup
    @sample_log = "01 | XX:XX:XX:XX:XX:XX,SSID,[WPA2_PSK],2021-2-26 18:46:18,6,-88,38.123456,-1.123456,675.60,3.25,WIFI"
    @parsed_log = MarauderToGeoData.parse_marauder_log(@sample_log)
    @log_list = [@parsed_log]
  end

  def test_parse_marauder_log
    assert_equal "XX:XX:XX:XX:XX:XX", @parsed_log[:mac_address]
    assert_equal "SSID", @parsed_log[:ssid]
    assert_equal "WPA2_PSK", @parsed_log[:security]
    assert_equal "2021-2-26 18:46:18", @parsed_log[:timestamp]
    assert_equal 6, @parsed_log[:channel]
    assert_equal -88, @parsed_log[:rssi]
    assert_in_delta 38.123456, @parsed_log[:latitude], 0
    assert_in_delta -1.123456, @parsed_log[:longitude], 0
    assert_equal 675.60, @parsed_log[:altitude]
  end

  def test_generate_geojson
    geojson = MarauderToGeoData.generate_geojson(@log_list)
    assert_equal "FeatureCollection", geojson[:type]
    assert_equal 1, geojson[:features].size
  end

  def test_generate_kml
    kml = MarauderToGeoData.generate_kml(@log_list)
    assert kml.include?("<kml xmlns=\"http://www.opengis.net/kml/2.2\">")
    assert kml.include?("<name>SSID (XX:XX:XX:XX:XX:XX)</name>")
  end

  def test_read_input_file
    File.stub(:readlines, [@sample_log]) do
      parsed_data = MarauderToGeoData.read_input_file("fake_log.txt")
      assert_equal 1, parsed_data.size
    end
  end

  def test_remove_duplicates
    log_list = [
      { mac_address: "XX:XX:XX:XX:XX:XX", rssi: -88 },
      { mac_address: "YY:YY:YY:YY:YY:YY", rssi: -90 },
      { mac_address: "XX:XX:XX:XX:XX:XX", rssi: -85 }
    ]
    filtered_list = MarauderToGeoData.filter_duplicates(log_list)
    assert_equal 2, filtered_list.size
  end
end
