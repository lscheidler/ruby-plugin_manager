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
      if argument[:type] == :initialize
        if options_empty or options_unsupported or not is_argument_valid?(options.first, argument)
          if argument[:optional]
            instance_variable_set '@'+argument[:name].to_s, argument[:default]
          else
            missing_arguments << argument[:name].to_s
          end
        else
          instance_variable_set '@'+argument[:name].to_s, options.first[argument[:name]]
        end
      end
    end
    raise ArgumentError.new('missing keywords: ' + missing_arguments.join(', ')) unless missing_arguments.empty?

    after_initialize
  end

  # run code after plugin initialization
  def after_initialize
  end

  # add class *name* to plugin manager
  #
  # @param name [Class] class
  def self.inherited name
    @pm = PluginManager.instance
    @pm << name

    # add plugin_argument from superclass to class (MyPluginClass < MyPluginSuperClass < Plugin)
    if @arguments
      @arguments.each do |arg|
        name.plugin_argument arg[:name], optional: arg[:optional], default: arg[:default], argument_settings: arg[:settings], validator: arg[:validator]
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
    @pm = PluginManager.instance
    @pm.add_to_group self, group: group
  end

  # add plugin argument to initialize
  #
  # @param argument [String] argument name
  # @param default [Object] default value for argument, optional must be true
  # @param optional [Bool] argument is optional
  # @param argument_settings [Hash] settings for argument
  # @param validator [Proc] validator
  def self.plugin_argument argument, default: nil, optional: false, argument_settings: {}, validator: nil
    result = add_command_line_parameter argument, type: :initialize, argument_settings: argument_settings
    result[:default]  = default
    result[:optional] = optional
    result[:validator] = validator
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
  # @param type [Symbol] type of argument
  # @param argument_settings [Hash] settings for argument
  def self.add_command_line_parameter argument, type: :all, argument_settings: {}
    @arguments ||= []
    argument = {name: argument, type: type, settings: argument_settings}
    @arguments << argument
    argument
  end

  # return list of arguments
  #
  # @param types [Array] types to return
  # @return [Array] arguments
  def self.arguments types: [:all]
    result = []
    @arguments and @arguments.each do |argument|
      if types.include? :all or types.include? argument[:type]
        result << argument
      end
    end
    result
  end

  # @return if arguments are required to initialize plugin
  def self.arguments_required?
    result = false
    @arguments and @arguments.each do |argument|
      if argument[:type] == :initialize and argument[:optional] == false
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
  # @param argument [Hash] argument settings
  # @return if argument key exist and value is valid
  def is_argument_valid? options, argument
    result = options.has_key? argument[:name]
    result = (result and argument[:validator].yield(options[argument[:name]])) unless argument[:validator].nil?
    result
  end
end
