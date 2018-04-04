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

        add_command_line_parameter :name, argument_settings: {type: String, description: 'description for name parameter'}
      end

      @options = OptionParser.new
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

    it 'shouldn\'t have a group nogroup in PluginManager' do
      expect{@pm.each(group: 'nogroup')}.to raise_error(PluginManager::GroupNotFoundException)
    end

    it 'should extend OptionParser' do
      @pm.extend_option_parser @options
      expect(@options.summarize).to include(/--TestPlugin-name STRING/)
    end
  end

  describe 'PluginWithOptToken' do
    before(:all) do
      class PluginWithOptToken < Plugin
        OPT_TOKEN = 'test'

        plugin_group 'mytestgroup'

        add_command_line_parameter :name, argument_settings: {type: String, description: 'description for name parameter'}
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
        plugin_argument :argument2, argument_settings: {type: String, description: 'description for argument2 parameter'}
        plugin_argument :argument3, optional: true
        plugin_argument :argument4, optional: true, default: true, argument_settings: {type: TrueClass, description: 'description for argument4 parameter'}
        plugin_argument :argument5, optional: true, default: '123'

        add_command_line_parameter :name, argument_settings: {type: String, description: 'description for name parameter'}
      end

      @options = OptionParser.new
    end

    it 'should extend OptionParser' do
      @pm.extend_option_parser @options
      expect(@options.summarize).to include(/--PluginWithArguments-name STRING/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument1 STRING/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument2 STRING/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument3 STRING/)
      expect(@options.summarize).to include(/--\[no-\]PluginWithArguments-argument4/)
      expect(@options.summarize).to include(/--PluginWithArguments-argument5 STRING/)
    end

    it 'should require argument1 and argument2' do
      expect {@pm['PluginWithArguments'].new argument1: 'abc'}.to raise_error(ArgumentError, 'missing keywords: argument2')
    end

    it 'should set instance variables for required arguments' do
      plugin = @pm['PluginWithArguments'].new argument1: 'abc', argument2: 'xyz'
      expect(plugin.argument1).to eq('abc')
      expect(plugin.argument2).to eq('xyz')
    end

    it 'should set instance variables for optional arguments' do
      plugin = @pm['PluginWithArguments'].new argument1: 'abc', argument2: 'xyz'
      expect(plugin.argument3).to eq(nil)
    end

    it 'should set instance variables for optional argument with default values' do
      plugin = @pm['PluginWithArguments'].new argument1: 'abc', argument2: 'xyz'
      expect(plugin.argument4).to eq(true)
      expect(plugin.argument5).to eq('123')
    end
  end
end
