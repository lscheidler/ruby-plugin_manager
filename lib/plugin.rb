# @author Lars Eric Scheidler <lscheidler@liventy.de>
require_relative 'plugin_manager'

# plugin object
class Plugin
  # version
  VERSION = PluginManager::VERSION

  # argument token to use instead of class name
  OPT_TOKEN = nil

  def initialize *options
  end

  # add class *name* to plugin manager
  #
  # @param name [Class] class
  def self.inherited name
    @pm = PluginManager.instance
    @pm << name
  end

  # add plugin to group
  #
  # @param group [String] plugin group
  def self.plugin_group group
    @pm = PluginManager.instance
    @pm.add_to_group self, group: group
  end

  # add command line parameter
  #
  # @param var_name [String] name of command line parameter
  # @param inner [Bool] is an inner paramater
  # @param argument_settings [Hash] settings for argument
  def self.add_command_line_parameter var_name, inner: false, argument_settings: {}
    if inner
      @inner_arguments ||= []
      @inner_arguments << [var_name, argument_settings]
    else
      @arguments ||= []
      @arguments << [var_name, argument_settings]
    end
  end

  # return list of arguments
  #
  # @param add [Bool] :add add public arguments
  # @param inner [Bool] :inner add inner arguments
  def self.arguments add: false, inner: false
    result = []
    result += @arguments        if @arguments and (add or not inner)
    result += @inner_arguments  if @inner_arguments and inner
    result
  end
end
