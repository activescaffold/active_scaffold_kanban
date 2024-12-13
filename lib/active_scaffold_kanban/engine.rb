module ActiveScaffoldKanban
  class Engine < ::Rails::Engine
    initializer 'active_scaffold_kanban.action_view' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, ActiveScaffold::Helpers::KanbanHelpers
      end
    end
  end
end
