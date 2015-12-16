# Rails Application Template

```zsh
$ mkdir [APP_NAME]; cd [APP_NAME]
$ rbenv local [RUBY_VERSION]
$ bundle init
$ sed -i '' -e 's/# gem "rails"/gem "rails"/g' Gemfile
$ bundle install -j4 --path vendor/bundle
```

when rbenv-gemsets.

```zsh
$ mkdir [APP_NAME]; cd [APP_NAME]
$ rbenv local [RUBY_VERSION]
$ echo [APP_NAME] > .rbenv-gemsets
$ bundle init
$ sed -i '' -e 's/# gem "rails"/gem "rails"/g' Gemfile
$ bundle install -j4
```


```zsh
$ bundle exec rails new . --skip-bundle --skip-git --skip-test-unit --database --skip-puma mysql --template https://raw.githubusercontent.com/kzy52/rails-template/master/web_template.rb
```

Or, Run in the interactive

```zsh
$ git clone git@github.com:kzy52/rails-template.git
$ cd rails-template
$ sh install.sh
```
