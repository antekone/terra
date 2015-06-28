require 'mechanize'
require 'logger'
require 'json'
require 'yaml'

class Build
  def initialize(url)
    @url = url
    @log = Logger.new "mech.log"
    @client = Mechanize.new
    @client.log = @log
    @client.redirect_ok = false
  end

  def init()
    # login
    if not File.exists? ".creds.yml"
      puts("No .creds.yml file!")
      raise
    end

    creds = YAML.load_file(".creds.yml")
    page = @client.post("#{@url}/login", { "username" => creds[:username], "passwd" => creds[:password] })
    html = page.body

    if html =~ /authfail/i
      return false
    end

    true
  rescue Net::HTTP::Persistent::Error => e
    false
  rescue
    false
  end

  def get_builders()
    page = @client.get("#{@url}/json/builders")
    JSON.parse(page.body).keys
  rescue Net::HTTP::Persistent::Error => e
    []
  end

  def force_build(builder_name, reason)
    page = @client.post("#{@url}/builders/#{builder_name}/force", {
      "forcescheduler" => "force",
      "reason" => reason,
      "branch" => "",
      "revision" => "",
      "repository" => "",
      "project" => "",
      "property1_name" => "",
      "property1_value" => "",
      "property2_name" => "",
      "property2_value" => "",
      "property3_name" => "",
      "property3_value" => "",
      "property4_name" => "",
      "property4_value" => "" })

    page.body.scan("see <a href").size > 0
  end

  def get_activity(builder_name)
    page = @client.get("#{@url}/json/builders")
    builders = JSON.parse(page.body)
    return nil if not builders.has_key?(builder_name)
    builder = builders[builder_name]
    return builder['state']
  end

  def get_builder_info(builder_name)
    page = @client.get("#{@url}/json/builders/#{builder_name}")
    JSON.parse(page.body)
  end

  def get_build_id_info(builder_name, build_id)
    page = @client.get("#{@url}/json/builders/#{builder_name}/builds/#{build_id}")
    JSON.parse(page.body)
  end

  def get_activities()
    page = @client.get("#{@url}/json/builders")
    JSON.parse(page.body)
  end
end

# vim:set ts=2 sw=2:
