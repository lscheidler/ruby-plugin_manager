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

require "spec_helper"

describe PluginManager do
  before(:all) do
    @pm = PluginManager.instance
  end

  it "has a version number" do
    expect(PluginManager::VERSION).not_to be nil
  end

  it "should exist one instance only" do
    expect(@pm.__id__).to be(PluginManager.instance.__id__)
  end

  describe Plugin do
    before(:all) do
      class TestPlugin < Plugin
        plugin_group 'mytestgroup'
        plugin_group 'mytestgroup2'

        add_command_line_parameter :name, type: String, description: 'description for name parameter'

        def after_initialize
          puts 'after_initialize'
        end
      end

      @options = OptionParser.new
    end

    after(:all) do
      # disable plugin to circumvent unwanted output in @pm.initialize_plugins
      @pm['TestPlugin'].plugin_setting :disabled, true
    end

    it "has a version number" do
      expect(Plugin::VERSION).not_to be nil
    end

    it 'should be listed in PluginManager' do
      expect(@pm['TestPlugin']).to be(TestPlugin)
    end

    it 'should be listed in PluginManager group' do
      groups = @pm.each(group: 'mytestgroup') {|x| x}

      expect(groups).to include(TestPlugin.to_s)
    end

    it 'has groups listed in class' do
      expect(@pm['TestPlugin'].plugin_groups).to eq(['mytestgroup', 'mytestgroup2'])
    end

    it 'should be listed in second PluginManager group' do
      groups = @pm.each(group: 'mytestgroup2') {|x| x}

      expect(groups).to include(TestPlugin.to_s)
    end

    it 'shouldn\'t have a group nogroup in PluginManager' do
      expect{@pm.each(group: 'nogroup')}.to raise_error(PluginManager::GroupNotFoundException)
    end

    it 'should extend OptionParser' do
      @result = @pm.extend_option_parser @options
      expect(@options.summarize).to include(/--TestPlugin-name STRING/)
      @options.parse(['--TestPlugin-name', 'test'])

      expect(@result['TestPlugin'][:name]).to eq('test')
    end

    it 'should run method after_initialize' do
      expect{@pm['TestPlugin'].new({name: 'test'})}.to output("after_initialize\n").to_stdout
    end
  end

  describe 'PluginWithOptToken' do
    before(:all) do
      class PluginWithOptToken < Plugin
        OPT_TOKEN = 'test'

        plugin_group 'mytestgroup'

        add_command_line_parameter :name, type: String, description: 'description for name parameter'
      end

      @options = OptionParser.new
    end

    it 'should extend OptionParser and use OPT_TOKEN' do
      @pm.extend_option_parser @options
      expect(@options.summarize).to include(/--test-name STRING/)
    end
  end

  describe 'PluginWithArguments' do
    before(:all) do
      class PluginWithArguments < Plugin
        attr_reader :argument1, :argument2, :argument3, :argument4, :argument5

        plugin_group 'mytestgroup'

        plugin_argument :argument1
        plugin_argument :argument2, type: String, description: 'description for argument2 parameter'
        plugin_argument :argument3, optional: true
        plugin_argument :argument4, optional: true, default: true, description: 'description for argument4 parameter', type: TrueClass
        plugin_argument :argument5, optional: true, default: '123'
        plugin_argument :argument6, optional: true, type: Array

        add_command_line_parameter :name, type: String, description: 'description for name parameter'
      end

      @options = OptionParser.new
    end

    it 'should extend OptionParser' do
      @pm.extend_option_parser @options
      expect(@options.summarize).to include(/--PluginWithArguments-name STRING/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument1 STRING/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument2 STRING/)
      expect(@options.summarize).to include(/description for argument2 parameter/)
      expect(@options.summarize).not_to include(/bla/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument3 STRING/)
      expect(@options.summarize).to include(/--\[no-\]PluginWithArguments-argument4.*/)
      expect(@options.summarize).to include(/description for argument4 parameter/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument5 STRING/)
    end

    it 'parses arguments' do
      @result = @pm.extend_option_parser @options
      @options.parse(['--PluginWithArguments-name', 'test', '--PluginWithArguments-argument4', '--PluginWithArguments-argument6', 'hello', '--PluginWithArguments-argument6', 'world'])

      expect(@result['PluginWithArguments'][:name]).to eq('test')
      expect(@result['PluginWithArguments'][:argument4]).to be(true)
      expect(@result['PluginWithArguments'][:argument6]).to eq(["hello", "world"])

      @options.parse(['--PluginWithArguments-name', 'test', '--no-PluginWithArguments-argument4'])
      expect(@result['PluginWithArguments'][:argument4]).to be(false)
    end

    it 'should require argument1 and argument2' do
      expect {@pm['PluginWithArguments'].new argument1: 'abc', name: 'test'}.to raise_error(ArgumentError, 'missing keywords: argument2')
    end

    it 'should set instance variables for required arguments' do
      plugin = @pm['PluginWithArguments'].new argument1: 'abc', argument2: 'xyz', name: 'test'
      expect(plugin.argument1).to eq('abc')
      expect(plugin.argument2).to eq('xyz')
    end

    it 'should set instance variables for optional arguments' do
      plugin = @pm['PluginWithArguments'].new argument1: 'abc', argument2: 'xyz', name: 'test'
      expect(plugin.argument3).to eq(nil)
    end

    it 'should set instance variables for optional argument with default values' do
      plugin = @pm['PluginWithArguments'].new argument1: 'abc', argument2: 'xyz', name: 'test'
      expect(plugin.argument5).to eq('123')
    end
  end

  describe 'PluginWithExcludedArguments' do
    before(:all) do
      class PluginWithExcludedArguments < Plugin
        attr_reader :argument1, :argument2, :argument3, :argument4, :argument5

        plugin_group 'mytestgroup'

        plugin_argument :argument1
        plugin_argument :argument2, type: String, description: 'description for argument2 parameter'
        plugin_argument :argument3, group: :command_line, optional: true
        plugin_argument :argument4, optional: true, default: true, description: 'description for argument4 parameter', type: TrueClass
        plugin_argument :argument5, group: :command_line2, optional: true, default: '123'

        add_command_line_parameter :name, type: String, description: 'description for name parameter'
      end

      @options = OptionParser.new
    end

    it 'should extend OptionParser' do
      @pm.extend_option_parser @options, argument_groups: [:command_line, :command_line2]
      expect(@options.summarize).not_to include(/--PluginWithExcludedArguments-name STRING/)
      expect(@options.summarize).not_to include(/--PluginWithExcludedArguments-argument1 STRING/)
      expect(@options.summarize).not_to include(/--PluginWithExcludedArguments-argument2 STRING/)
      expect(@options.summarize).not_to include(/description for argument2 parameter/)
      expect(@options.summarize).to include(/--PluginWithExcludedArguments-argument3 STRING/)
      expect(@options.summarize).not_to include(/--\[no-\]PluginWithExcludedArguments-argument4.*/)
      expect(@options.summarize).not_to include(/description for argument4 parameter/)
      expect(@options.summarize).to include(/--PluginWithExcludedArguments-argument5 STRING/)
    end

    it 'shows default values' do
      expect(@options.summarize.index{|x| x =~ /--PluginWithExcludedArguments-argument5/}).to be(1)
      expect(@options.summarize).to include(/default: 123/)
      expect(@options.summarize.index{|x| x =~ /default: 123/}).to be(2)
    end
  end

  describe 'PluginInitialize' do
    before(:all) do
      class PluginInitialize < Plugin
        attr_reader :argument1, :argument3, :argument4

        plugin_group 'mytestgroup'

        plugin_argument :argument1
        plugin_argument :argument3, optional: true
        plugin_argument :argument4

        def after_initialize
          @argument1 = @argument1*3
        end
      end
    end

    it 'should not initialize plugin because of missing argument' do
      @pm.initialize_plugins
      expect(@pm.instance 'PluginInitialize').to be(nil)
    end

    it 'should initialize plugin because of existing argument' do
      @pm.initialize_plugins({'PluginInitialize' => {argument1: 'asdf'}}, defaults: {argument4: '1234'})
      expect(@pm.instance 'PluginInitialize').not_to be(nil)
      expect(@pm.instance('PluginInitialize').argument1).to eq('asdfasdfasdf')
      expect(@pm.instance('PluginInitialize').argument4).to eq('1234')
    end
  end

  describe 'PluginNoAutoInitialize' do
    before(:all) do
      class PluginNoAutoInitialize < Plugin
        attr_reader :argument1, :argument3

        plugin_group 'mytestgroup'
        plugin_setting :skip_auto_initialization, true

        plugin_argument :argument1
        plugin_argument :argument3, optional: true
      end
    end

    it 'should not initialize plugin because of plugin_setting :skip_auto_initialization' do
      @pm.initialize_plugins({'PluginNoAutoInitialize' => {argument1: 'asdf'}})
      expect(@pm.instance 'PluginNoAutoInitialize').to be(nil)
    end
  end

  describe 'DisabledPlugin' do
    before(:all) do
      class DisabledPlugin< Plugin
        attr_reader :argument1, :argument3

        plugin_group 'mytestgroup'
        plugin_setting :disabled, true

        plugin_argument :argument1
        plugin_argument :argument3, optional: true
      end
    end

    it 'should not initialize plugin because of plugin_setting :disabled' do
      @pm.initialize_plugins({'DisabledPlugin' => {argument1: 'asdf'}})
      expect(@pm.instance 'DisabledPlugin').to be(nil)
    end

    it 'should not show up in each because of plugin_setting :disabled' do
      @pm.each do |plugin_klass, plugin_instance|
        expect(plugin_klass).not_to be(DisabledPlugin)
      end
    end
  end

  describe 'PluginArgumentValidation' do
    before(:all) do
      class PluginArgumentValidation < Plugin
        attr_reader :argument1, :argument2

        plugin_group 'mytestgroup'

        plugin_argument :argument1, validator: Proc.new {|x| not x.nil? and not x.empty?}
        plugin_argument :argument2, validator: Proc.new {|x| not x.nil? and x.is_a? Integer}
      end
    end

    it 'should raise an exception, because arguments are not valid' do
      expect {@pm['PluginArgumentValidation'].new argument1: ""}.to raise_error(ArgumentError, 'missing keywords: argument1, argument2')
    end

    it 'should initialize the plugin' do
      plugin=@pm['PluginArgumentValidation'].new argument1: "abc", argument2: 2
      expect(plugin).not_to be(nil)
      expect(plugin.argument1).to eq("abc")
      expect(plugin.argument2).to be(2)
    end
  end

  describe 'PluginArgumentInitialize' do
    before(:all) do
      class PluginArgumentInitialize < Plugin
        attr_reader :argument1, :argument2, :argument3, :argument4, :argument5, :command_line_arguments

        plugin_group 'mytestgroup'

        plugin_argument :argument1
        plugin_argument :argument2, type: String, description: 'description for argument2 parameter'
        plugin_argument :argument3, group: :command_line, optional: true
        plugin_argument :argument4, optional: true, default: true, description: 'description for argument4 parameter', type: TrueClass
        plugin_argument :argument5, group: :command_line2, optional: true, default: '123'

        add_command_line_parameter :name, type: String, description: 'description for name parameter'

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
              if argument[:settings] and argument[:settings][:simple]
                @command_line_arguments += [ '--'+argument[:name].to_s ]
              else
                @command_line_arguments += [ '--'+argument[:name].to_s, argument[:value]]
              end
            end
          end
        end
      end

      @options = OptionParser.new
      @pm.extend_option_parser @options
      @options.parse(['--PluginArgumentInitialize-argument3', 'test'])
    end

    it 'should extend OptionParser' do
      plugin=@pm['PluginArgumentInitialize'].new name: "test", argument1: "abc", argument2: 2
      expect(plugin.command_line_arguments).to eq(['--argument3', 'test'])
    end
  end
end
