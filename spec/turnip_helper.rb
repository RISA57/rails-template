require 'rails_helper'

require 'capybara/dsl'
require 'capybara/poltergeist'
require 'capybara/webkit'
require 'capybara/rspec'
require 'turnip'
require 'turnip/rspec'
require 'turnip/capybara'

Capybara.configure do |config|
  config.app_host   = 'http://localhost:3000'
  config.run_server = true
  config.javascript_driver = :poltergeist
  config.ignore_hidden_elements = true
end

Dir.glob('./spec/steps/**/*steps.rb') { |f| require f }
