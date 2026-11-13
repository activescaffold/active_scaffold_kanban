# frozen_string_literal: true

require 'minitest/autorun'

module ActiveScaffold
  module Actions
  end
end

require_relative '../../lib/active_scaffold/actions/kanban'

class KanbanActionsTest < Minitest::Test
  Column = Struct.new(:name)
  KanbanConfig = Struct.new(:replace_list_view, :group_by_column)
  ListConfig = Struct.new(:pagination)
  Config = Struct.new(:kanban, :columns, :list, :actions)
  Response = Struct.new(:status)

  class Controller
    def self.before_action(*); end

    def self.after_action(*); end

    include ActiveScaffold::Actions::Kanban

    attr_accessor :ordered_ids, :successful
    attr_reader :active_scaffold_config, :kanban_column, :params, :reorder_calls, :response

    def initialize(view: nil, replace_list_view: false, actions: [])
      @params = {view: view}
      @active_scaffold_config = Config.new(
        KanbanConfig.new(replace_list_view, :status),
        {status: Column.new(:status)},
        ListConfig.new(20),
        actions
      )
      @successful = true
      @reorder_calls = 0
      @response = Response.new(200)
    end

    def successful?
      successful
    end

    def reorder
      @reorder_calls += 1
    end

    def kanban_view?
      @kanban_view
    end

    public :reorder_cards, :set_error_status_code, :setup_kanban
  end

  def test_setup_kanban_for_explicit_view
    controller = Controller.new(view: 'kanban')

    controller.setup_kanban

    assert controller.kanban_view?
    assert_equal :status, controller.kanban_column.name
    assert_nil controller.active_scaffold_config.list.pagination
  end

  def test_setup_kanban_when_it_replaces_list_view
    controller = Controller.new(replace_list_view: true)

    controller.setup_kanban

    assert controller.kanban_view?
    assert_nil controller.active_scaffold_config.list.pagination
  end

  def test_setup_kanban_leaves_normal_list_unchanged
    controller = Controller.new(view: 'list')

    controller.setup_kanban

    refute controller.kanban_view?
    assert_equal 20, controller.active_scaffold_config.list.pagination
  end

  def test_reorders_after_successful_column_change
    controller = Controller.new(actions: [:sortable])
    controller.ordered_ids = %w[3 1 2]

    controller.reorder_cards

    assert_equal 1, controller.reorder_calls
  end

  def test_does_not_reorder_without_ids_or_sortable_action
    controller = Controller.new(actions: [:sortable])
    controller.reorder_cards

    controller.ordered_ids = %w[1 2]
    controller.active_scaffold_config.actions.clear
    controller.reorder_cards

    assert_equal 0, controller.reorder_calls
  end

  def test_does_not_reorder_failed_update_and_sets_bad_request
    controller = Controller.new(actions: [:sortable])
    controller.ordered_ids = %w[1 2]
    controller.successful = false

    controller.reorder_cards
    controller.set_error_status_code

    assert_equal 0, controller.reorder_calls
    assert_equal 400, controller.response.status
  end

  def test_successful_update_keeps_response_status
    controller = Controller.new

    controller.set_error_status_code

    assert_equal 200, controller.response.status
  end
end
