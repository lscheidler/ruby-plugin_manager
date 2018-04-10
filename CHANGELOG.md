0.1.3
=====

- introduce plugin\_setting, which sets settings for plugin, which are
  respected by PluginManager
  - :skip\_auto\_initialization: skip initialization in
    PluginManager.initialize\_plugins for this plugin
  - :disabled: disable plugin for initialisation and PluginManager.each

0.1.2
=====

- inherit plugin\_argument from parent (e.g. MyPlugin inherit all arguments
  from MyBasePlugin with MyPlugin < MyBasePlugin < Plugin)
- added initialize\_plugins, which initializes all plugins, when required
  arguments are handed over
- added missing development\_dependency to yard
- refactored PluginManager.each

0.1.1
=====

- Added class method plugin\_argument, which adds arguments to a plugin

0.1.0
=====

- Initial release
