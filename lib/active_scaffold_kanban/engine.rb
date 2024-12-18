module ActiveScaffoldKanban
  class Engine < ::Rails::Engine
    initializer 'active_scaffold_kanban.action_view' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, ActiveScaffold::Helpers::KanbanHelpers
      end
    end

    initializer 'active_scaffold_kanban.config_list' do
      ActiveSupport.on_load :active_scaffold_config_list do
        require 'active_scaffold_kanban/config_list'
        ActiveScaffold::Actions::ConfigList.prepend(ActiveScaffoldKanban::ConfigListAction)
        ActiveScaffold::Helpers::ConfigListHelpers.prepend(ActiveScaffoldKanban::ConfigListHelpers)
      end
    end
  end
end
