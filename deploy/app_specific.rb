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

  alias_method :original_bootstrap, :bootstrap
  def bootstrap()
    application = ARGV.shift

    if (application == nil)
      # prompt the user
      print "Bootstrap docs or dmc? [docs, dmc] "
      application = gets.strip
    end

    if (application == 'docs')
      # nothing to do
      puts "docs"
    elsif (application == 'dmc')
      # get the RunDMC configuration
      rundmc_config = File.read("deploy/rundmc-appservers.xml")
      @properties.sort {|x,y| y <=> x}.each do |k, v|
        rundmc_config.gsub!("@#{k}", v)
      end

      # Put it into the main configuration
      @config = get_config
      @config.gsub!(/[[:blank:]]*@ml.rundmc-appservers/, rundmc_config)
    else
      # invalid. show correct options
      @logger.error "#{application} is not a valid bootstrap option. Specify 'docs' or 'dmc'."
      exit!
    end

    original_bootstrap
  end

  alias_method :original_wipe, :wipe
  def wipe()
    # get the RunDMC configuration
    rundmc_config = File.read("deploy/rundmc-appservers.xml")
    @properties.sort {|x,y| y <=> x}.each do |k, v|
      rundmc_config.gsub!("@#{k}", v)
    end

    # Put it into the main configuration
    @config = get_config
    @config.gsub!(/[[:blank:]]*@ml.rundmc-appservers/, rundmc_config)

    original_wipe
  end


  def deploy_docs_request(data)

    # TODO is there a roxy-level mechanism to require a gem?
    begin
    require 'net/http/digest_auth'
    rescue LoadError
      @logger.error "The net-http-digest_auth gem is required for this feature."
      @logger.error "Run: $ gem install net-http-digest_auth"
      exit!
    end

    # Send the docs to MarkLogic
    uri = uri = URI.parse(
      sprintf('http://%s:%s/apidoc/setup/build.xqy',
              @properties['ml.server'],
              @properties['ml.maintenance-port']))
    uri.user = @properties['ml.user']
    uri.password = @properties['ml.password']
    @logger.info(
      sprintf("Trying %s@%s:%s",
              uri.user, uri.host, uri.port))

    http = Net::HTTP.new(uri.host, uri.port)
    # This process takes time. Make sure we wait for the answer.
    http.read_timeout = 900

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(data)

    response = http.request(request)
    @logger.debug("response: #{response} #{response.code}")
    if response.code == "401"
      if response['www-authenticate']
        # Server wants digest auth.
        @logger.info("Trying digest auth")
        digest_auth = Net::HTTP::DigestAuth.new
        auth = digest_auth.auth_header(uri, response['www-authenticate'], 'POST')
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(data)
        request.add_field 'Authorization', auth
        response = http.request(request)
      else
        # Server wants basic auth.
        @logger.info("Trying basic auth")
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(data)
        request.basic_auth(uri.user, uri.password)
        response = http.request(request)
      end
    end

    @logger.info("response: #{response}")
    @logger.info("response: #{response.body}")
  end

  def deploy_docs()
    if @properties['ml.build-version'] != ""
      version = @properties['ml.build-version']
    else
      print "MarkLogic version for docs? (x.y) "
      version = gets.strip
    end

    if @properties['ml.build-zip-path'] != ""
      zip = @properties['ml.build-zip-path']
    else
      print "Full path to zip file? "
      zip = gets.strip
    end

    if @properties['ml.server'] == "localhost"
      if !File.exist? zip
        @logger.error "No file found at #{zip}"
        exit!
      end
    end

    if @properties['ml.build-clean'] != ""
      clean = @properties['ml.build-clean'].strip.match(
        /(true|t|yes|y|1)$/i) != nil
    else
      print "Clean? [y/N] "
      clean = gets.strip.match(/(true|t|yes|y|1)$/i) != nil
    end

    data = {
      "version" => version,
      "zip" => zip,
      "clean" => clean }

    actions = nil
    if (@properties['ml.build-actions'])
      actions = @properties['ml.build-actions'].split(/[\s,]+/)
    end
    if (actions != nil and actions.length > 0)
      data["action"] = actions
    end

    deploy_docs_request(data)
  end

  def test()
    # Run xray unit tests
    print Dir.pwd + "\n"

    cmd = sprintf(
      "./src/xray/test-runner.sh -d %s -u http://%s:%s/xray",
      "test",
      @properties['ml.server'],
      @properties['ml.api-port'])
    @logger.info(sprintf("Trying %s", cmd))
    cmd += sprintf(" -c %s:%s",
                   @properties['ml.user'],
                   @properties['ml.password'])
    system(cmd)
  end

  def xray()
    test()
  end

end
