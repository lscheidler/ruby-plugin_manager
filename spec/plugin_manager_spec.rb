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
      class TestPlugin < Plugin
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
end
