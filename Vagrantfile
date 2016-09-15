dir = File.dirname(File.expand_path(__FILE__))
vagrant_home = (ENV['VAGRANT_HOME'].to_s.split.join.length > 0) ? ENV['VAGRANT_HOME'] : "#{ENV['HOME']}/.vagrant.d"
vagrant_dot  = (ENV['VAGRANT_DOTFILE_PATH'].to_s.split.join.length > 0) ? ENV['VAGRANT_DOTFILE_PATH'] : "#{dir}/.vagrant"

require 'yaml'
require "#{dir}/lib/ruby/deep_merge.rb"
require 'httpclient'

if File.file?("#{dir}/../config/vm/.api-config.yml")
  apiConfig = YAML.load_file("#{dir}/../config/vm/.api-config.yml")
  httpClient = HTTPClient.new
  apiConfig['files'].each do |fileDownload|
    localFilename = "#{dir}/../archives/#{fileDownload['filename']}"
    if !Dir.exist?("#{dir}/../archives")
      Dir.mkdir("#{dir}/../archives")
    end
    if !File.exist?(localFilename)
      puts "Downloading project file: #{fileDownload['filename']}"
      response = httpClient.get("#{apiConfig['url']}download/project-file/#{fileDownload['filename']}", nil, [['X-Auth-Token', apiConfig['token']]])
      File.write(localFilename, response.body)
    end
  end
end

configValues = YAML.load_file("#{dir}/../config/vm/config.yaml")

if File.file?("#{dir}/../config/vm/config.local.yaml")
  custom = YAML.load_file("#{dir}/../config/vm/config.local.yaml")
  configValues.deep_merge!(custom)
end

$data = configValues['config']

Vagrant.require_version '>= 1.8.0'

if $data.has_key?('nodes')
    load "MultiNode.rb"
else
    load "SingleNode.rb"
end
