# @author Lars Eric Scheidler <lscheidler@liventy.de>
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
    missing_arguments = []
    self.class.arguments.each do |argument|
      if argument[:type] == :initialize
        if options.empty? or options.first.nil? or not (options.first.class.method_defined? :[] and options.first.class.method_defined? :has_key? and options.first.has_key? argument[:name])
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
        name.plugin_argument arg[:name], optional: arg[:optional], default: arg[:default], argument_settings: arg[:settings]
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
  def self.plugin_argument argument, default: nil, optional: false, argument_settings: {}
    result = add_command_line_parameter argument, type: :initialize, argument_settings: argument_settings
    result[:default]  = default
    result[:optional] = optional
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
end
