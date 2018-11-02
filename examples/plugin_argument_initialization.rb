#!/usr/bin/env ruby
#
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

require 'optparse'
require 'plugin'

class PluginArgumentInitialization < Plugin
  plugin_argument :help, group: :command_line, optional: true, description: 'show help', type: TrueClass, simple: true

  def initialize_argument argument, options, options_empty: true, options_unsupported: true
    super

    @command_line_arguments ||= []
    case argument[:group]
    when :command_line
      if not is_argument_valid?(argument, :value, argument[:validator])
        if not argument[:optional]
          raise ArgumentError.new
        end
      else
        if argument[:simple]
          @command_line_arguments += [ '--'+argument[:name].to_s ]
        else
          @command_line_arguments += [ '--'+argument[:name].to_s, argument[:value]]
        end
      end
    end
  end

  def run
    command = ['/bin/echo']
    command += @command_line_arguments
    command << 'test'

    puts '$ ' + command.join(' ')
    IO.popen(command) do |io|
      puts io.read
    end
  end
end

options = OptionParser.new
pm      = PluginManager.instance

pm.extend_option_parser options
options.parse!

plugin = pm['PluginArgumentInitialization'].new
plugin.run
