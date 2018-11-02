# Copyright 2018 Lars Eric Scheidler
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'plugin_manager'

# plugin object
class Plugin
  # version
  VERSION = PluginManager::VERSION

  # argument token to use instead of class name
  OPT_TOKEN = nil

  # set instance variables for all arguments set with *plugin_argument*
  #
  # @raise [ArgumentError] if a required argument is missing, which is added with *plugin_argument*
  def initialize *options
    options_empty = (options.empty? or options.first.nil?) ? true : false
    options_unsupported = (not options_empty and options.first.class.method_defined? :[] and options.first.class.method_defined? :has_key?) ? false : true

    missing_arguments = []
    self.class.arguments.each do |argument|
      begin
        initialize_argument argument, options, options_empty: options_empty, options_unsupported: options_unsupported
      rescue ArgumentError
        missing_arguments << argument[:name].to_s
      end
    end
    raise ArgumentError.new('missing keywords: ' + missing_arguments.join(', ')) unless missing_arguments.empty?

    after_initialize
  end

  # check and initialize plugin argument
  #
  # @param argument [Hash] argument
  # @param options [Hash] options
  # @param options_empty [Bool] options is empty
  # @param options_unsupported [Bool] options is unsupported
  def initialize_argument argument, options, options_empty: true, options_unsupported: true
    if options_empty or options_unsupported or (not is_argument_valid?(options.first, argument[:name], argument[:validator]) and not is_argument_valid?(argument, :value, argument[:validator]))
      if argument[:optional]
        instance_variable_set '@'+argument[:name].to_s, argument[:default]
      else
        raise ArgumentError.new
      end
    else
      if is_argument_valid?(argument, :value, argument[:validator])
        instance_variable_set '@'+argument[:name].to_s, argument[:value]
      else
        instance_variable_set '@'+argument[:name].to_s, options.first[argument[:name]]
      end
    end
  end

  # run code after plugin initialization
  def after_initialize
  end

  # add class *name* to plugin manager
  #
  # @param name [Class] class
  def self.inherited name
    pm = PluginManager.instance
    pm << name

    # add plugin_argument from superclass to class (MyPluginClass < MyPluginSuperClass < Plugin)
    if @arguments
      @arguments.each do |arg|
        name.plugin_argument arg[:name],
          default: arg[:default],
          description: arg[:description],
          group: arg[:group],
          optional: arg[:optional],
          simple: arg[:simple],
          type: arg[:type],
          validator: arg[:validator]
      end
    end

    if @plugin_settings
      @plugin_settings.each do |key, value|
        name.plugin_setting key, value
      end
    end
  end

  # add plugin to group
  #
  # @param group [String] plugin group
  def self.plugin_group group
    pm = PluginManager.instance
    pm.add_to_group self, group: group

    @plugin_groups ||= []
    @plugin_groups << group
  end

  # returns list of plugin_groups associated
  #
  # @return [Array] returns list of plugin_groups associated
  def self.plugin_groups
    @plugin_groups
  end

  # add plugin argument to initialize
  #
  # @param argument [String] argument name
  # @param default [Object] default value for argument, optional must be true
  # @param description [String] argument description
  # @param group [Symbol] argument group
  # @param optional [Bool] argument is optional
  # @param simple [Bool] is simple argument
  # @param type [Class] argument type
  # @param validator [Proc] validator
  def self.plugin_argument argument,
                              default: nil,
                              description: nil,
                              group: :initialize,
                              optional: false,
                              simple: nil,
                              type: nil,
                              validator: nil

    result = add_command_line_parameter argument, group: group, description: description, type: type
    result[:default]      = default
    result[:optional]     = optional
    result[:simple]       = simple
    result[:validator]    = validator
  end

  # set plugin setting, which are respected by PluginManager
  #
  # @param setting [String] name of setting
  # @param value [Object] value of setting
  def self.plugin_setting setting, value
    @plugin_settings ||= {}
    @plugin_settings[setting.to_sym] = value
  end

  # get plugin setting
  #
  # @param setting [String] name of setting
  # @return [Object] value of setting
  def self.plugin_settings setting
    result = nil
    if not @plugin_settings.nil?
      result = @plugin_settings[setting.to_sym]
    end
    result
  end

  # add command line parameter
  #
  # @param argument [String] name of command line parameter
  # @param group [Symbol] group of argument
  # @param description [String] description of argument
  # @param type [Class] type of argument
  def self.add_command_line_parameter argument, group: :all, description: nil, type: nil
    @arguments ||= []
    argument = {name: argument, group: group, description: description, type: type}
    @arguments << argument
    argument
  end

  # return list of arguments
  #
  # @param groups [Array] groups to return
  # @return [Array] arguments
  def self.arguments groups: nil
    result = []
    @arguments and @arguments.each do |argument|
      if groups.nil? or groups.include? :all or groups.include? argument[:group]
        result << argument
      end
    end
    result
  end

  # @return if arguments are required to initialize plugin
  def self.arguments_required?
    result = false
    @arguments and @arguments.each do |argument|
      if argument[:group] == :initialize and argument[:optional] == false
        result = true
        break
      end
    end
    result
  end

  private

  # check, if argument key exist and value is valid
  #
  # @param options [Hash] map with options
  # @param name [String,Symbol] name of argument
  # @param validator [Proc] value validator
  # @return if argument key exist and value is valid
  def is_argument_valid? options, name, validator
    result = options.has_key? name
    result = (result and validator.yield(options[name])) unless validator.nil?
    result
  end
end
