require 'active_scaffold_kanban/engine'
require 'active_scaffold_kanban/version'
require 'active_scaffold_sortable' # ensure dependent gem is loaded

module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, File.dirname(__FILE__))
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, File.dirname(__FILE__))
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self, File.dirname(__FILE__))
  end
end

ActiveScaffold.stylesheets << 'active_scaffold_kanban'
ActiveScaffold.javascripts << 'active_scaffold_kanban'
