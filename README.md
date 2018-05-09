# PluginManager

[![Build Status](https://travis-ci.org/lscheidler/ruby-plugin_manager.svg?branch=master)](https://travis-ci.org/lscheidler/ruby-plugin_manager)

Simple plugin manager

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plugin_manager', git: 'https://github.com/lscheidler/ruby-plugin_manager'
```

And then execute:

    $ bundle

## Usage

### Basic

application.rb:

```ruby
require 'bundler/setup'
require 'plugin_manager'
require_relative 'my_plugin'

class Application
  def initialize
    # get instance of plugin manager
    @pm = PluginManager.instance

    # get plugin MyPlugin class
    @my_plugin = @pm['MyPlugin']
  end
end
```

my\_plugin.rb:

```ruby
require 'bundler/setup'
require 'plugin'

class MyPlugin < Plugin
end
```

### Groups

application.rb:

```ruby
    @pm.each(group: 'mygroup') do |plugin|
      p = plugin.new
    end
```

my\_plugin.rb:

```ruby
require 'bundler/setup'
require 'plugin'

class MyPlugin < Plugin
  plugin_group 'mygroup'
end
```

### OptionParser extension

application.rb:

```ruby
    @options = OptionParser.new
    @pm.extend_option_parser @options
    @options.parse!
```

my\_plugin.rb:

```ruby
class MyPlugin < Plugin
  add_command_line_parameter :name, argument_settings: {type: String, description: 'description for name parameter'}
end
```

### Plugin arguments

application.rb:

```ruby
require 'bundler/setup'
require 'plugin_manager'
require_relative 'my_plugin'

class Application
  def initialize
    # get instance of plugin manager
    @pm = PluginManager.instance

    # get plugin MyPlugin class
    @my_plugin_class = @pm['MyPlugin']
    @my_plugin = @my_plugin_class.new argument1: 'abc'

    # returns 'abc'
    @my_plugin.argument1
  end
end
```

my\_plugin.rb:

```ruby
require 'bundler/setup'
require 'plugin'

class MyPlugin < Plugin
  attr_accessor :argument1, :argument4

  # required argument1
  plugin_argument :argument1

  # optional argument2, with argument settings for OptionParser
  plugin_argument :argument2, optional: true, argument_settings: {type: String, description: 'description for argument2 parameter'}

  # optional argument3 with default
  plugin_argument :argument3, optional: true, default: 'Hello World'

  # argument4 with validator
  plugin_argument :argument4, validator: Proc.new {|x| not x.nil? and not x.empty?}

  # optional argument5, with argument settings for OptionParser
  plugin_argument :argument5, description: 'description for argument5 parameter', optional: true, argument_settings: {type: String}
end
```

### Plugin initialisation

application.rb:

```ruby
    @pm = PluginManager.instance

    @pm.initialize_plugins({'MyPlugin' => {argument1: 'asdf'}}, defaults: {argument4: '1234'})

    $ returns instance of MyPlugin
    @pm.instance('MyPlugin')

    # returns 'asdfasdfasdf'
    @pm.instance('MyPlugin').argument1

    # returns '1234'
    @pm.instance('MyPlugin').argument4
```

my\_plugin.rb:

```ruby
class MyPlugin < Plugin
  ...

  # run code directly after MyPlugin.initialize
  def after_initialize
    @argument1 = @argument1*3
  end
end
```

### Plugin settings

Plugin settings, which are respected by PluginManager

my\_plugin.rb:

```ruby
class MyPlugin < Plugin
  # skip initialisation in PluginManager.initialize_plugins for this plugin
  plugin_setting :skip_auto_initialization, true

  # disable plugin for initialisation and PluginManager.each
  plugin_setting :disabled, true
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lscheidler/ruby-plugin_manager.


## License

The gem is available as open source under the terms of the [Apache 2.0 License](http://opensource.org/licenses/Apache-2.0).

