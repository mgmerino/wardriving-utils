require "nokogiri"
require "optparse"
require "json"

module MarauderToGeoData
  @@options = {}

  def self.parse_options
    OptionParser.new do |opts|
      opts.banner = <<~BANNER
        Usage: ruby marauder_to_geodata.rb [OPTIONS]

        Converts Marauder log files to GeoJSON or KML formats.

        Options:
          --input_file FILE      Input file in Marauder log format
          --output_file FILE     Output file in GeoJSON or KML format, depending on the extension:
                                    - .json -> GeoJSON
                                    - .kml  -> KML
          --help                 Shows this help message.

        Examples:
          ruby marauder_to_geodata.rb --input_file marauder_log.txt --output_file wifi_map.json
          ruby marauder_to_geodata.rb --input_file marauder_log.txt --output_file wifi_map.kml
      BANNER

      opts.on("-i", "--input FILE", "Input file") do |input_file|
        @@options[:input_file] = input_file
      end

      opts.on("-o", "--output FILE", "Output file (uses the file extension to infer the desired format)") do |output_file|
        @@options[:output_file] = output_file
        ext = File.extname(output_file).downcase
        @@options[:format] = ext == ".kml" ? "kml" : "json"
      end

      opts.on("--help", "Shows this help message") do
        puts opts
        exit
      end
    end.parse!
  end

  def self.parse_marauder_log(line)
    data = line.strip.split(",")

    return if data.length != 11

    {
      mac_address: data[0].split("|")[1].strip,
      ssid: data[1].strip,
      security: data[2].strip,
      timestamp: data[3].strip,
      channel: data[4].to_i,
      rssi: data[5].to_i,
      latitude: data[6].to_f,
      longitude: data[7].to_f,
      altitude: data[8].to_f,
      gps_precision: data[9].to_f,
      network_type: data[10].strip
    }
  end

  def self.generate_kml(log_lines)
    Nokogiri::XML::Builder.new do |xml|
      xml.kml(xmlns: "http://www.opengis.net/kml/2.2") {
        xml.Document {
          log_lines.each do |log|
            xml.Placemark {
              xml.name "#{log[:ssid]} (#{log[:mac_address]})"
              xml.description "Channel: #{log[:channel]}, RSSI: #{log[:rssi]} dBm, Sec: #{log[:security]}, #{log[:network_type]}"
              xml.Point {
                xml.coordinates "#{log[:longitude]},#{log[:latitude]},#{log[:altitude]}"
              }
            }
          end
        }
      }
    end.to_xml
  end

  def self.generate_geojson(log_lines)
    {
      type: "FeatureCollection",
      features: log_lines.map do |log|
        {
          type: "Feature",
          properties: {
            ssid: log[:ssid],
            mac_address: log[:mac_address],
            security: log[:security],
            channel: log[:channel],
            rssi: log[:rssi],
            timestamp: log[:timestamp]
          },
          geometry: {
            type: "Point",
            coordinates: [log[:longitude], log[:latitude]]
          }
        }
      end
    }
  end

  def self.read_input_file(file)
    File.readlines(file).map { |line| parse_marauder_log(line) }.compact
  end

  def self.write_output_file(raw_logs)
    output_content = case @@options[:format]
                     when "json" then JSON.pretty_generate(generate_geojson(raw_logs))
                     when "kml" then generate_kml(raw_logs)
                     else
                       puts "ERROR: Invalid format, use json or kml"
                       exit
                     end
    File.write(@@options[:output_file], output_content)
  end

  def self.run
    parse_options

    unless @@options[:input_file] && @@options[:output_file]
      puts "ERROR: Missing required arguments: input_file and output_file"
      puts OptionParser.new.parse(["--help"])
      exit
    end

    parsed_lines = read_input_file(@@options[:input_file])
    write_output_file(parsed_lines)
    puts "✅ File successfully written to #{@@options[:output_file]}"
  rescue StandardError => e
    puts "ERROR: #{e.message}"
    exit
  end
end

MarauderToGeoData.run if __FILE__ == $0
