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

require 'singleton'

require_relative "plugin_manager/version"
require_relative "plugin_manager/group_not_found_exception"

# plugin manager singleton
class PluginManager
  include Singleton

  # @!attribute [rw] scope
  #   @return [String] module scope of plugins
  attr_accessor :scope

  # @!attribute [rw] log
  #   @return [Logger] logger
  attr_accessor :log

  def initialize
    @plugins = {}
    @plugin_instances = {}
    @groups  = {}
  end

  # initialize plugins, where options are avaible or not required
  #
  # @param options [Hash] hash with options, where plugin_name is the key
  def initialize_plugins options={}, defaults: {}
    @plugins.each do |plugin_name, klass|
      next if not klass.plugin_settings(:skip_auto_initialization).nil? and klass.plugin_settings(:skip_auto_initialization)
      next if not klass.plugin_settings(:disabled).nil? and klass.plugin_settings(:disabled)

      if options[plugin_name].kind_of? Hash
        begin
          @plugin_instances[plugin_name] = klass.new(defaults.merge(options[plugin_name]))
        rescue ArgumentError => exc
          @log and @log.debug exc.message
        end
      else
        begin
          @plugin_instances[plugin_name] = klass.new(defaults)
        rescue ArgumentError => exc
          @log and @log.debug exc.message
        end
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

  # iterate over all plugins or plugin group
  #
  # @param group [String] plugin group
  # @yield [klass, instance] apply block to each plugin
  # @raise [PluginManager::GroupNotFoundException]
  def each group: nil
    arr = if group.nil?
      @plugins
    elsif @groups.has_key? group.to_sym
      @groups[group.to_sym]
    else
      raise GroupNotFoundException.new group
    end

    arr.each do |plugin_name, plugin|
      next if plugin.plugin_settings(:disabled)

      yield plugin, @plugin_instances[plugin_name]
    end
  end

  # extend option parser object with arguments from plugins
  #
  # @param opt_parser [OptionParser] option parser object to extend
  # @param types [Array] argument types to extend option parser with
  # @return [Hash] passed command line arguments with provided values
  def extend_option_parser opt_parser, types: nil
    result = {}
    @plugins.each do |plugin_name, plugin|
      plugin_name = ( @scope ) ? plugin_name.sub(@scope + '::', '') : plugin_name
      opt_token = ( plugin::OPT_TOKEN ) ? plugin::OPT_TOKEN : plugin_name

      plugin.arguments(types: types).each do |argument|
        settings = ( argument[:settings].nil? ) ? {} : argument[:settings]
        settings[:default] = argument[:default]

        add_argument result, opt_parser, opt_token, plugin_name, argument[:name], settings
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
  def add_argument result, opt_parser, opt_token, plugin_name, arg_name, type: nil, description: " ", default: nil
    default = 'default: ' + default.to_s if not default.nil?
    arg = []

    block = if type == TrueClass or type == FalseClass
      arg << "--[no-]#{opt_token}-#{arg_name}".gsub(/_/, '-')

      proc do |val|
        result[plugin_name] ||= {}
        result[plugin_name][arg_name] = val
      end
    elsif type == Array
      arg += [ "--#{opt_token}-#{arg_name} STRING".gsub(/_/, '-'), String ]

      proc do |val|
        result[plugin_name] ||= {}
        result[plugin_name][arg_name] ||= []
        result[plugin_name][arg_name] << val
      end
    else
      arg += [ "--#{opt_token}-#{arg_name} STRING".gsub(/_/, '-'), String ]

      proc do |val|
        result[plugin_name] ||= {}
        result[plugin_name][arg_name] = val
      end
    end

    arg << description unless description.nil?
    arg << default unless default.nil?

    opt_parser.on(*arg, block)
  end
end
