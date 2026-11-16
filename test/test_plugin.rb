# frozen_string_literal: true

require 'test_helper'

class KanbanPluginTest < Minitest::Test
  def test_entry_point_registers_assets
    assert_includes ActiveScaffold.stylesheets, 'active_scaffold_kanban'
    assert_includes ActiveScaffold.javascripts, 'active_scaffold_kanban'
  end

  def test_entry_point_loads_action_configuration_and_helpers
    expected_sources = {
      ActiveScaffold::Actions::Kanban.instance_method(:setup_kanban) =>
        'lib/active_scaffold/actions/kanban.rb',
      ActiveScaffold::Config::Kanban.instance_method(:initialize) =>
        'lib/active_scaffold/config/kanban.rb',
      ActiveScaffold::Helpers::KanbanHelpers.instance_method(:kanban_columns) =>
        'lib/active_scaffold/helpers/kanban_helpers.rb'
    }

    expected_sources.each do |method, relative_path|
      assert_equal File.expand_path("../#{relative_path}", __dir__), method.source_location.first
    end
  end

  def test_engine_defines_named_initializers
    assert_equal(
      %w[active_scaffold_kanban.action_view active_scaffold_kanban.config_list],
      ActiveScaffoldKanban::Engine.initializers.map(&:name)
    )
  end

  def test_action_view_initializer_installs_kanban_helpers
    run_initializer('active_scaffold_kanban.action_view')
    ActiveSupport.run_load_hooks(:action_view, ActionView::Base)

    assert_includes ActionView::Base.ancestors, ActiveScaffold::Helpers::KanbanHelpers
  end

  def test_config_list_initializer_installs_kanban_extensions
    require 'active_scaffold_config_list'
    original_action = replace_constant(ActiveScaffold::Actions, :ConfigList, Module.new)
    original_helpers = replace_constant(ActiveScaffold::Helpers, :ConfigListHelpers, Module.new)

    run_initializer('active_scaffold_kanban.config_list')

    assert_includes ActiveScaffold::Actions::ConfigList.ancestors, ActiveScaffoldKanban::ConfigListAction
    assert_includes ActiveScaffold::Helpers::ConfigListHelpers.ancestors, ActiveScaffoldKanban::ConfigListHelpers
  ensure
    replace_constant(ActiveScaffold::Actions, :ConfigList, original_action) if original_action
    replace_constant(ActiveScaffold::Helpers, :ConfigListHelpers, original_helpers) if original_helpers
  end

  private

  def run_initializer(name)
    ActiveScaffoldKanban::Engine.initializers.find { |initializer| initializer.name == name }.run
  end

  def replace_constant(namespace, name, value)
    previous = namespace.const_get(name, false) if namespace.const_defined?(name, false)
    namespace.send(:remove_const, name) if previous
    namespace.const_set(name, value)
    previous
  end
end
