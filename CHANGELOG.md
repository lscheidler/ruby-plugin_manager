0.1.9 (2018-10-30)
==================

- bugfix for parsing command line arguments correctly

0.1.8 (2018-10-26)
==================

- pass type through plugin\_argument to PluginManager.extend\_option\_parser
- show default value in option parser

0.1.7 (2018-05-09)
==================

- added description to plugin\_argument

0.1.6 (2018-04-26)
==================

- introduce Plugin.after\_initialize, which can be used to run code after
  plugin initialization
- changed license to Apache-2.0
- added copyrigth notice to source files

0.1.5 (2018-04-17)
==================

- introduce validator to plugin\_argument, which validates passed argument
  against Proc

0.1.4 (2018-04-12)
==================

- plugin argument initialisation now supports all kind of class instances,
  which support [] and has\_key? methods (e.g. Hash)

0.1.3 (2018-04-10)
==================

- introduce plugin\_setting, which sets settings for plugin, which are
  respected by PluginManager
  - :skip\_auto\_initialization: skip initialization in
    PluginManager.initialize\_plugins for this plugin
  - :disabled: disable plugin for initialisation and PluginManager.each

0.1.2 (2018-04-10)
==================

- inherit plugin\_argument from parent (e.g. MyPlugin inherit all arguments
  from MyBasePlugin with MyPlugin < MyBasePlugin < Plugin)
- added initialize\_plugins, which initializes all plugins, when required
  arguments are handed over
- added missing development\_dependency to yard
- refactored PluginManager.each

0.1.1 (2018-04-04)
==================

- Added class method plugin\_argument, which adds arguments to a plugin

0.1.0 (2018-04-03)
==================

- Initial release
