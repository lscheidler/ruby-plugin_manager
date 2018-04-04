# PluginManager

Simple plugin manager

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plugin_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plugin_manager

## Usage

### Basic

application.rb:

```ruby
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
require 'plugin'

class MyPlugin < Plugin
  attr_accessor :argument1

  # required argument1
  plugin_argument :argument1

  # optional argument2, with argument settings for OptionParser
  plugin_argument :argument2, optional: true, argument_settings: {type: String, description: 'description for argument2 parameter'}

  # optional argument3 with default
  plugin_argument :argument3, optional: true, default: 'Hello World'
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lscheidler/ruby-plugin\_manager.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

