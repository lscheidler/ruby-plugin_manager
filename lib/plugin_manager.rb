require 'singleton'

require_relative "plugin_manager/version"
require_relative "plugin_manager/group_not_found_exception"

# plugin manager singleton
class PluginManager
  include Singleton

  # @!attribute [rw] scope
  #   @return [String] module scope of plugins
  attr_accessor :scope

  def initialize
    @plugins = {}
    @plugin_instances = {}
    @groups  = {}
  end

  # initialize plugins, where options are avaible or not required
  #
  # @param options [Hash] hash with options, where plugin_name is the key
  def initialize_plugins options={}
    @plugins.each do |plugin_name, klass|
      if options[plugin_name].kind_of? Hash
        @plugin_instances[plugin_name] = klass.new options[plugin_name]
      elsif not klass.arguments_required?
        @plugin_instances[plugin_name] = klass.new
      end
    end
  end

  # append plugin to manager
  #
  # @param plugin [Plugin] plugin to add
  def << plugin
    @plugins[plugin.to_s] = plugin
  end

  # add plugin to group
  #
  # @param plugin [Plugin] plugin to add
  # @param group [String] plugin group
  def add_to_group plugin, group:
    group_sym = group.to_sym
    @groups[group_sym] ||= {}
    @groups[group_sym][plugin.to_s] = plugin
  end

  # return plugin from plugin manager
  #
  # @param plugin [String] name of plugin without scope
  # @return [Plugin] plugin
  def [] plugin
    if @scope
      @plugins[@scope + '::' + plugin]
    else
      @plugins[plugin]
    end
  end

  # return plugin instance from plugin manager
  #
  # @param plugin [String] name of plugin without scope
  # @return [Plugin] plugin instance
  def instance plugin
    if @scope
      @plugin_instances[@scope + '::' + plugin]
    else
      @plugin_instances[plugin]
    end
  end

  # iterate over all plugins
  #
  # @param group [String] plugin group
  # @param instance [Bool] return plugin instance
  # @yield apply block to each plugin
  # @raise [PluginManager::GroupNotFoundException]
  def each group: nil, instance: false
    if group.nil?
      @plugins.each do |plugin_name, plugin|
        if not instance
          yield plugin
        else
          yield @plugin_instances[plugin_name]
        end
      end
    elsif @groups.has_key? group.to_sym
      @groups[group.to_sym].each do |plugin_name, plugin|
        yield plugin
      end
    else
      raise GroupNotFoundException.new group
    end
  end

  # extend option parser object with arguments from plugins
  #
  # @param opt_parser [OptionParser] option parser object to extend
  # @return [Hash] passed command line arguments with provided values
  def extend_option_parser opt_parser
    result = {}
    @plugins.each do |plugin_name, plugin|
      plugin_name = ( @scope ) ? plugin_name.sub(@scope + '::', '') : plugin_name
      opt_token = ( plugin::OPT_TOKEN ) ? plugin::OPT_TOKEN : plugin_name

      plugin.arguments.each do |argument|
        add_argument result, opt_parser, opt_token, plugin_name, argument[:name], argument[:settings]
      end
    end
    result
  end

  # add argument to option parser
  #
  # @param result [Hash] hash to save parsed command line arguments to
  # @param opt_parser [OptionParser] option parser object to extend
  # @param opt_token [String] option token
  # @param plugin_name [String] plugin name
  # @param arg_name [String] argument name
  # @param type [Class] type of argument [String, Array, Bool]
  # @param description [String] description of command line argument
  def add_argument result, opt_parser, opt_token, plugin_name, arg_name, type: nil, description: ' '
    if type == TrueClass or type == FalseClass
      opt_parser.on("--[no-]#{opt_token}-#{arg_name}".gsub(/_/, '-'), description) do |val|
        result[plugin_name] ||= {}
        result[plugin_name][arg_name] = val
      end
    elsif type == Array
      opt_parser.on("--#{opt_token}-#{arg_name} STRING".gsub(/_/, '-'), String, description) do |val|
        result[plugin_name] ||= {}
        result[plugin_name][arg_name] ||= []
        result[plugin_name][arg_name] << val
      end
    else
      opt_parser.on("--#{opt_token}-#{arg_name} STRING".gsub(/_/, '-'), String, description) do |val|
        result[plugin_name] ||= {}
        result[plugin_name][arg_name] = val
      end
    end
  end
end
