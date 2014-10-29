#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the stuff in deploy/lib/server_config.rb
#
require 'net/http'

class ServerConfig
  def my_custom_method()
    @logger.info(@properties["ml.content-db"])
  end

  def deploy_docs()
    print "MarkLogic version for docs? (x.y) "
    version = gets.strip
    print "Full path to zip file? "
    zip = gets.strip
    print "Clean? [y/N] "
    clean = gets.strip.match(/(true|t|yes|y|1)$/i) != nil

    xsd_dir = ""
    if (File.exist? "/var/opt/MarkLogic")
      # Linux
      xsd_dir = "/var/opt/MarkLogic/Config"
    elsif (File.exist? ENV['HOME'])
      # Mac
      xsd_dir = "#{ENV['HOME']}/Library/MarkLogic/Config"
    elsif (File.exist? )
      # Windows
      xsd_dir = "MarkLogic/Config"
    else
      abort("Cannot find the directory with XSDs")
    end

    puts "XSD directory is #{xsd_dir}"

    # Send the docs to MarkLogic
    http = Net::HTTP.new(@properties['ml.server'], @properties['ml.maintenance-port'])
    # This process takes time. Make sure we wait for the answer.
    http.read_timeout = 900
    response = http.post("/apidoc/setup/build.xqy", "version=#{version}&zip=#{zip}&help-xsd-dir=#{xsd_dir}&clean=#{clean}")

    puts "response: #{response}"
  end
end
