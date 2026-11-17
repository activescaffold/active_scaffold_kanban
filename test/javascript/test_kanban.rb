# frozen_string_literal: true

require 'javascript_test_helper'

class KanbanJavascriptTest < ActiveScaffold::TestSupport::Javascript::TestCase
  def test_loads_sortable_and_kanban_adapters
    visit_javascript_fixture

    assert_javascript 'typeof jQuery.fn.sortable === "function"'
    assert_javascript 'typeof ActiveScaffold.sortable === "function"'
    assert_javascript 'typeof ActiveScaffold.kanban === "function"'
    assert_no_javascript_errors
  end

  def test_initializes_columns_and_posts_card_changes
    with_plugin_assets('active_scaffold_kanban') do
      visit_javascript_fixture kanban_fixture

      assert_selector '.cards.ui-sortable', count: 2, visible: :all
      execute_script <<~JS
        var item = jQuery('#card-7');
        var source = jQuery('#todo-cards');
        var target = jQuery('#done-cards');
        var start = source.sortable('option', 'start');
        var receive = target.sortable('option', 'receive');
        start.call(source[0], {}, {item: item});
        target.append(item);
        receive.call(target[0], {}, {item: item});
      JS

      assert_javascript 'window.kanbanAjax.url === "/cards/7"'
      assert_javascript 'window.kanbanAjax.method === "POST"'
      assert_javascript 'String(window.kanbanAjax.data).includes("value=done")'
      assert_no_javascript_errors
    end
  end

  private

  def kanban_fixture
    <<~HTML
      <script>
        jQuery.rails.fire = function() { return true; };
        jQuery.ajax = function(options) {
          window.kanbanAjax = options;
          return {};
        };
      </script>
      <div class="active-scaffold">
        <div class="kanban" data-reorder-url="/cards/reorder" data-change-url="/cards/--ID--"
             data-reorder-key="cards" data-format="card-(.*)">
          <div class="kanban-column" data-value="todo"><div id="todo-cards" class="cards">
            <div id="card-7" class="card" data-value="7"></div>
          </div></div>
          <div class="kanban-column" data-value="done"><div id="done-cards" class="cards"></div></div>
        </div>
      </div>
    HTML
  end

  def with_plugin_assets(*assets)
    original = ActiveScaffold.javascripts.dup
    ActiveScaffold.javascripts.replace(assets)
    yield
  ensure
    ActiveScaffold.javascripts.replace(original)
  end
end
