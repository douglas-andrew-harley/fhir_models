# Top level include file that brings in all the necessary code
require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'nokogiri'
require 'date_time_precision'
require 'date_time_precision/format/iso8601'
require 'mime/types'
require 'bcp47'

root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))

# Need to require Hashable first
require File.join(root,'lib','bootstrap','Hashable.rb')

Dir.glob(File.join(root, 'lib','bootstrap','*.rb')).each do |file|
  require file
end
Dir.glob(File.join(root, 'lib','bootstrap','**','*.rb')).each do |file|
  require file
end

# Require the generated code
Dir.glob(File.join(root, 'lib','fhir','*.rb')).each do |file|
  require file
end
Dir.glob(File.join(root, 'lib','fhir','**','*.rb')).each do |file|
  require file
end

