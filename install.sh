#!/bin/bash

set -eu

echo "What is the applications name?"
read APP_NAME

if [ -z "$APP_NAME" ]; then
  echo "Please enter the name of application"
  exit 1
fi

echo "Ruby's version?"
read RUBY_VERSION

RUBY_VERSION_CHECK=`rbenv versions | grep $RUBY_VERSION`
if [ -z "$RUBY_VERSION_CHECK" ]; then
  echo "ruby version $RUBY_VERSION not installed"
  exit 1
fi

echo "Do you generate which applications?"
ANSWER1="web"
ANSWER2="api"
ANSWER3="web+api"

select ANSWER in "$ANSWER1" "$ANSWER2" "$ANSWER3"
do
  if [ -z "$ANSWER" ]; then
    continue
  else
    mkdir $APP_NAME; cd $APP_NAME
    rbenv local $RUBY_VERSION
    bundle init
    sed -i '' -e 's/# gem "rails"/gem "rails"/g' Gemfile
    bundle install -j4 --path vendor/bundle

    case $REPLY in
      1)
        # web
        bundle exec rails new . --force --skip-bundle --skip-git --skip-test-unit --database mysql --template ../web_template.rb
        ;;
      2)
        # api
        #bundle exec rails new . --force --skip-bundle --skip-git --skip-test-unit --skip-sprockets --skip-javascript --database mysql --template ../api_template.rb
        ;;
      3)
        # web+api
        #bundle exec rails new . --force --skip-bundle --skip-git --skip-test-unit --database mysql --template ../web_and_api_template.rb
        ;;
    esac

    break
  fi
done
