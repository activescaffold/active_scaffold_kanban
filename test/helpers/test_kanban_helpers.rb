# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/core_ext/enumerable'

module ActiveScaffold
  module Helpers
  end
end

require_relative '../../lib/active_scaffold/helpers/kanban_helpers'

class KanbanHelpersTest < Minitest::Test
  Association = Struct.new(:name)
  Column = Struct.new(:association, :options)
  KanbanConfig = Struct.new(:description_method, :group_by_column)
  SortableConfig = Struct.new(:column)
  Config = Struct.new(:actions, :kanban, :sortable)
  Record = Struct.new(:summary)

  class Helper
    include ActiveScaffold::Helpers::KanbanHelpers

    attr_accessor :config_list_params, :kanban_view
    attr_reader :active_scaffold_config
    attr_writer :available_columns

    def initialize(actions: [], sortable_column: nil)
      @active_scaffold_config = Config.new(
        actions,
        KanbanConfig.new(:summary, :status),
        SortableConfig.new(sortable_column)
      )
      @kanban_column = Column.new(nil, {})
      @available_columns = [['Backlog', :backlog], ['Done', :done]]
      @kanban_view = false
    end

    def available_kanban_columns
      @available_columns
    end

    def association_column!
      @kanban_column.association = Association.new(:status)
    end

    def list_record_view
      @kanban_view = kanban_view
      super
    end

    def url_for(options)
      "#{options[:action]}/#{options[:id]}"
    end

    def params_for(**options)
      options
    end

    def active_scaffold_tbody_id
      'tasks-tbody'
    end
  end

  def test_selects_and_orders_configured_columns
    helper = Helper.new(actions: [:config_list])
    helper.config_list_params = %i[done backlog]

    assert_equal [['Done', :done], ['Backlog', :backlog]], helper.user_kanban_columns
  end

  def test_uses_all_columns_without_config_list
    helper = Helper.new
    helper.config_list_params = [:done]

    assert_equal [['Backlog', :backlog], ['Done', :done]], helper.user_kanban_columns
  end

  def test_association_columns_are_selected_by_id
    backlog = Struct.new(:id).new(10)
    done = Struct.new(:id).new(20)
    helper = Helper.new(actions: [:config_list])
    helper.association_column!
    helper.available_columns = [['Backlog', backlog], ['Done', done]]
    helper.config_list_params = [:'20']

    assert_equal [['Done', done]], helper.user_kanban_columns
  end

  def test_record_partial_changes_only_in_kanban_view
    helper = Helper.new

    assert_equal 'list_record', helper.list_record_view
    helper.kanban_view = true
    assert_equal 'kanban_card', helper.list_record_view
  end

  def test_description_uses_configured_method
    helper = Helper.new

    assert_equal 'Details', helper.kanban_description(Record.new('Details'))
    helper.active_scaffold_config.kanban.description_method = nil
    assert_nil helper.kanban_description(Record.new('Details'))
  end

  def test_data_attributes_include_reorder_url_when_sortable
    helper = Helper.new(actions: [:sortable], sortable_column: :position)

    assert_equal(
      {
        change_url: 'update_column/--ID--',
        format: '^[^_-](?:[A-Za-z0-9_-]*)-(.*)-row$',
        reorder_key: 'tasks-tbody',
        reorder_url: 'reorder/'
      },
      helper.kanban_data_attrs
    )
  end

  def test_data_attributes_omit_reorder_url_without_position_column
    helper = Helper.new(actions: [:sortable])

    refute_includes helper.kanban_data_attrs, :reorder_url
  end
end
