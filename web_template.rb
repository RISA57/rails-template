app_name = Pathname.new(`pwd`).basename.to_s.strip

# fetch ruby version
f = open(".ruby-version")
ruby_version  = f.gets.chomp!
f.close

template_repo_url = 'https://raw.githubusercontent.com/kzy52/rails-template/master'

ap_server_type = ask("What Application Server ? [unicorn|passenger|puma]")

if use_git = yes?('Do you want to git init? [y/n]') ? true : false
  git_repository_url = ask('Please enter the Git repository URL')
end

if use_errbit = yes?('Do you want to use errbit? [y/n]') ? true : false
  errbit_host = ask('Please enter the Errbit hostname')
  errbit_api_key = ask('Please enter the Errbit api key')
end

use_seed_fu = yes?('Do you want to use seed-fu gem? [y/n]') ? true : false
use_kaminari = yes?('Do you want to use kaminari gem? [y/n]') ? true : false
use_draper = yes?('Do you want to use draper gem? [y/n]') ? true : false
use_devise = yes?('Do you want to use devise gem? [y/n]') ? true : false
use_ransack = yes?('Do you want to use ransack gem? [y/n]') ? true : false
use_capistrano = yes?('Do you want to use capistrano gem? [y/n]') ? true : false
use_mail = yes?('Do you sent an email ? [y/n]') ? true : false

Bundler.with_clean_env do
  run 'bundle install -j4 --without production staging sandbox'
end

#run 'bundle exec spring binstub --all'

# Initialize Git
# ==================================================

create_file '.gitignore', <<-EOS
# Ignore bundler config.
/.bundle

# Ignore all logfiles and tempfiles.
/log/*
!/log/.keep
/tmp
/*.log

# Ignore other unneeded files.
*~
*.dump
*.swp

.DS_Store
.project
.pryrc
.rbenv-gemsets
.rspec
.sass-cache

/coverage/
/nbproject/
/spec/examples.txt
/vendor/bundle
EOS

if use_git
  git :init
  git add: '.'
  git commit: '-m "First commit"'
  git remote: "add origin #{git_repository_url}" if git_repository_url
  git flow: ' init -d'
end

# Gems
# ==================================================

remove_file 'Gemfile'
create_file 'Gemfile', "source 'https://rubygems.org'\n"

gem 'rails'
gem 'activemodel-serializers-xml', github: 'rails/activemodel-serializers-xml'

gem 'airbrake', '~> 5.4' if use_errbit
gem 'settingslogic'
gem 'enumerize'
gem 'dotenv-rails'
gem 'seed-fu', '~> 2.3' if use_seed_fu
gem 'draper' if use_draper
gem 'devise' if use_devise
gem 'kaminari' if use_kaminari
gem 'ransack' if use_ransack

# assets
gem 'coffee-rails', '~> 4.2'
gem 'uglifier', '>= 1.3.0'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'sass-rails', '~> 5.0'

# jquery
gem 'jquery-rails'

gem_group :mysql do
  gem 'mysql2', '~> 0.3.20'
end

gem_group :doc do
  gem 'yard'
end

gem_group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'listen', '~> 3.0.5'
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'thin'
  gem 'web-console'

  gem 'hirb'
  gem 'hirb-unicode'

  gem 'better_errors'
  gem 'binding_of_caller'

  if use_capistrano
    gem 'capistrano'
    gem 'capistrano-rails'
    gem 'capistrano-rbenv', github: 'capistrano/rbenv'
    gem 'capistrano-bundler'
  end

  # static code analysis
  gem 'brakeman'
  gem 'metric_fu'
  gem 'rails_best_practices'
  gem 'rubocop', require: false
  gem 'rubocop-checkstyle_formatter', require: false

  gem 'letter_opener_web' if use_mail
end

gem_group :test do
  gem 'database_rewinder'
  gem 'fuubar'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'spring-commands-rspec'
  gem 'timecop'

  gem 'capybara'
  gem 'capybara-webkit'
  gem 'poltergeist'
  gem 'selenium-webdriver'
  gem 'turnip'
end

gem_group :development, :test do
  gem 'awesome_print'
  gem 'byebug', platform: :mri
  gem 'factory_girl_rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # debug
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
end

gem_group :production, :staging, :sandbox do
  gem 'therubyracer', platforms: :ruby
  ap_server = ap_server_type.downcase
  gem = ap_server if %w(passenger unicorn puma).include?(ap_server)
end

Bundler.with_clean_env do
  run 'bundle update'
end

remove_file 'config/secrets.yml'
remove_file 'config/database.yml'
get "#{template_repo_url}/config/secrets.yml", 'config/secrets.yml'
get "#{template_repo_url}/config/database.yml", 'config/database.yml'

gsub_file 'config/database.yml', '%DATABASE_NAME%', app_name

# Create Database
# ==================================================

rake 'db:create'

# Add app rake
# ==================================================

rakefile('app.rake') do
<<-EOS
namespace :app do
  desc 'Initialize Database'
  task init: 'db:load_config' do
    %w(db:create db:migrate db:seed).each do |t|
      Rake::Task[t].invoke
    end
  end

  desc 'Reset Database'
  task reset: 'db:load_config' do
    %w(db:migrate:reset db:seed).each do |t|
      Rake::Task[t].invoke
    end
  end
end
EOS
end

inject_into_file 'config/application.rb', after: "# -- all .rb files in that directory are automatically loaded." do <<-EOS.chomp

    config.time_zone = 'Tokyo'

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    I18n.enforce_available_locales = true
    config.i18n.available_locales = [:ja]
    config.i18n.default_locale = :ja

    config.generators do |g|
      g.assets false
      g.helper false

      g.test_framework :rspec, fixtures: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
      g.decorator   false
    end
  EOS
end

# Locale settings
# ==================================================

run 'mkdir -p config/locales/defaults/'
run 'mkdir -p config/locales/models/defaults/'
run 'mkdir -p config/locales/views/defaults/'
run 'touch config/locales/defaults/.keep'
run 'touch config/locales/models/defaults/.keep'
run 'touch config/locales/views/defaults/.keep'

remove_file 'config/locales/en.yml'

# Download I18n ja file
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/defaults/'
get "#{template_repo_url}/config/locales/views/defaults/ja.yml", 'config/locales/views/defaults/ja.yml'

# Add helper methods
# ==================================================

remove_file 'app/helpers/application_helper.rb'
get "#{template_repo_url}/app/helpers/application_helper.rb", 'app/helpers/application_helper.rb'

# Bullet gem settings
# ==================================================

inject_into_file 'config/environments/development.rb', after: '# config.action_view.raise_on_missing_translations = true' do <<-EOS.chomp


  # bullet settings
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = false
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
  end
EOS
end

# Environment settings
# ==================================================

get "#{template_repo_url}/config/environments/sandbox.rb", 'config/environments/sandbox.rb'
get "#{template_repo_url}/config/environments/staging.rb", 'config/environments/staging.rb'

# Install rspec
# ==================================================

run 'bundle exec spring binstub rspec'
generate 'rspec:install'

gsub_file 'spec/spec_helper.rb', /^=begin\n/, ''
gsub_file 'spec/spec_helper.rb', /^=end\n/, ''
uncomment_lines 'spec/rails_helper.rb', Regexp.escape("Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }")

append_file '.rspec' do <<-EOS
--format Fuubar
-r turnip
EOS
end

get "#{template_repo_url}/spec/support/database_rewinder.rb", 'spec/support/database_rewinder.rb'
get "#{template_repo_url}/spec/support/factory_girl.rb", 'spec/support/factory_girl.rb'

get "#{template_repo_url}/spec/turnip_helper.rb", 'spec/turnip_helper.rb'

# dotenv-rails settings
# ==================================================
get "#{template_repo_url}/env", '.env.example'
run 'cp .env.example .env'

# Settingslogic settings
# ==================================================

get "#{template_repo_url}/config/initializers/settings.rb", 'config/initializers/settings.rb'
get "#{template_repo_url}/config/application.yml", 'config/application.yml'

# enumerize settings
# ==================================================

get "#{template_repo_url}/config/locales/enumerize.ja.yml", 'config/locales/enumerize.ja.yml'

# kaminari settings
# ==================================================

if use_kaminari
  generate 'kaminari:config'
  generate 'kaminari:views', 'bootstrap3'
  get "#{template_repo_url}/config/locales/kaminari.ja.yml", 'config/locales/kaminari.ja.yml'
end

# Devise settings
# ==================================================

if use_devise
  generate 'devise:install'
  get "#{template_repo_url}/config/locales/devise.ja.yml", 'config/locales/devise.ja.yml'
  get "#{template_repo_url}/spec/support/devise.rb", 'spec/support/devise.rb'
end

# seed-fu settings
# ==================================================

if use_seed_fu
append_file 'db/seeds.rb' do <<-EOS

SeedFu.seed
EOS
end
end

# Capistrano settings
# ==================================================

if use_capistrano
  run 'cap install STAGES=production,staging,sandbox'

  uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/rbenv'")
  uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/bundler'")
  uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/rails/assets'")
  uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/rails/migrations'")

  remove_file 'config/deploy.rb'
  get "#{template_repo_url}/config/deploy.rb", 'config/deploy.rb'

  gsub_file 'config/deploy.rb', "set :application, ''", "set :application, '#{app_name}'"
  gsub_file 'config/deploy.rb', "set :repo_url, ''", "set :repo_url, '#{git_repository_url}'" if git_repository_url
  gsub_file 'config/deploy.rb', "set :rbenv_ruby, ''", "set :rbenv_ruby, '#{ruby_version}'"

  ap_server_restart_command = case ap_server_type.downcase.to_sym
                              when :passenger
                                "execute :touch, release_path.join('tmp/restart.txt')"
                              when :unicorn
                                get "#{template_repo_url}/lib/capistrano/tasks/unicorn.rake", 'lib/capistrano/tasks/unicorn.rake'
                                "invoke 'unicorn:restart'"
                              when :puma
                                get "#{template_repo_url}/lib/capistrano/tasks/puma.rake", 'lib/capistrano/tasks/puma.rake'
                                "invoke 'puma:restart'"
                              end

  if ap_server_restart_command
    gsub_file 'config/deploy.rb', '%RESTART_COMMAND%', ap_server_restart_command
  end
end

# Errbit settings
# ==================================================

if use_errbit
  initializer 'errbit.rb' do
  <<-EOS
Airbrake.configure do |config|
  config.host = '#{errbit_host}'
  config.project_id = -1
  config.project_key = '#{errbit_api_key}'

  config.environment = Rails.env
  config.ignore_environments = %w(development test)
end
  EOS
  end
end

# Assets
# ==================================================

remove_file 'app/assets/javascripts/application.js'
remove_file 'app/assets/stylesheets/application.css'

get "#{template_repo_url}/app/assets/javascripts/application.js", 'app/assets/javascripts/application.js'
get "#{template_repo_url}/app/assets/stylesheets/application.css", 'app/assets/stylesheets/application.css'
get "#{template_repo_url}/app/assets/stylesheets/base-importer.scss", 'app/assets/stylesheets/base-importer.scss'
get "#{template_repo_url}/app/assets/stylesheets/lib/base.scss", 'app/assets/stylesheets/lib/base.scss'
get "#{template_repo_url}/app/assets/stylesheets/lib/bootstrap-variables.scss", 'app/assets/stylesheets/lib/bootstrap-variables.scss'
get "#{template_repo_url}/app/assets/stylesheets/lib/component.scss", 'app/assets/stylesheets/lib/component.scss'
get "#{template_repo_url}/app/assets/stylesheets/lib/layout.scss", 'app/assets/stylesheets/lib/layout.scss'
get "#{template_repo_url}/app/assets/stylesheets/lib/shared.scss", 'app/assets/stylesheets/lib/shared.scss'

run 'mkdir -p app/assets/stylesheets/pages/'
run 'touch app/assets/stylesheets/pages/.keep'

# Layout
# ==================================================

remove_file 'app/views/layouts/application.html.erb'
get "#{template_repo_url}/app/views/layouts/application.html.erb", 'app/views/layouts/application.html.erb'

# Error handling
# ==================================================

get "#{template_repo_url}/app/controllers/concerns/error_handlers.rb", 'app/controllers/concerns/error_handlers.rb'
get "#{template_repo_url}/app/controllers/errors_controller.rb", 'app/controllers/errors_controller.rb'

if use_errbit
  inject_into_file 'app/controllers/concerns/error_handlers.rb', after: 'logger.info "Rendering #{code} with exception: #{exception.message}"' do <<-EOS.chomp

      Airbrake.notify(exception)
  EOS
  end
end

inject_into_file 'app/controllers/application_controller.rb', after: 'protect_from_forgery with: :exception' do <<-EOS.chomp


  include ErrorHandlers
EOS
end

inject_into_file 'config/routes.rb', after: 'Rails.application.routes.draw do' do <<-EOS.chomp

  get '*anything' => 'errors#routing_error'
EOS
end

get "#{template_repo_url}/app/views/errors/error_404.html.erb", 'app/views/errors/error_404.html.erb'
get "#{template_repo_url}/app/views/errors/error_422.html.erb", 'app/views/errors/error_422.html.erb'
get "#{template_repo_url}/app/views/errors/error_500.html.erb", 'app/views/errors/error_500.html.erb'

initializer 'exceptions_app.rb' do
<<-EOS
Rails.configuration.exceptions_app = ->(env) { ErrorsController.action(:render_error).call(env) }
EOS
end

# Mail settings
# ==================================================

if use_mail
  inject_into_file 'config/routes.rb', after: 'Rails.application.routes.draw do' do <<-EOS.chomp

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  EOS
  end

  append_file '.gitignore' do <<-EOS

/config/mail.yml
  EOS
  end

  gsub_file 'config/deploy.rb', "%LINKED_FILES%", "'config/mail.yml'"

  get "#{template_repo_url}/config/mail.yml.example", 'config/mail.yml.example'
  run 'cp config/mail.yml.example config/mail.yml'

  initializer 'mail.rb' do
  <<-EOS
    MAIL_CONFIG = YAML.load_file(File.expand_path(Rails.root.join("config", "mail.yml"), __FILE__))[Rails.env]
    Rails.application.config.action_mailer.delivery_method = MAIL_CONFIG['delivery_method'].to_sym
    Rails.application.config.action_mailer.raise_delivery_errors = MAIL_CONFIG['raise_delivery_errors']
    Rails.application.config.action_mailer.default_url_options = MAIL_CONFIG['default_url_options']

    case MAIL_CONFIG['delivery_method'].to_sym
    when :sendmail
      Rails.application.config.action_mailer.sendmail_settings = MAIL_CONFIG['sendmail_settings']
    when :smtp
      Rails.application.config.action_mailer.smtp_settings = MAIL_CONFIG['smtp_settings']
    end
  EOS
  end
end

# Add source
# ==================================================

if use_git
  git add: '.'
end

puts "SUCCESS!"
