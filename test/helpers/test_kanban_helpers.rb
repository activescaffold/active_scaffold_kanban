# frozen_string_literal: true

require 'test_helper'
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
  Config = Struct.new(:actions, :kanban, :sortable, :model)
  Record = Struct.new(:summary)
  Link = Struct.new(:type, :position)
  Model = Class.new

  class Helper
    include ActiveScaffold::Helpers::KanbanHelpers

    attr_accessor :config_list_params, :kanban_view
    attr_reader :active_scaffold_config
    attr_writer :available_columns

    def initialize(actions: [], sortable_column: nil)
      @active_scaffold_config = Config.new(
        actions,
        KanbanConfig.new(:summary, :status),
        SortableConfig.new(sortable_column),
        Model
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

  class BaseSourceHelper
    def action_link_html_options(*)
      {data: {}, inherited: true}
    end
  end

  class SourceHelper < BaseSourceHelper
    include ActiveScaffold::Helpers::KanbanHelpers

    AssociationRecord = Struct.new(:id, :name) do
      def to_label
        "Label #{name}"
      end
    end

    attr_reader :active_scaffold_config, :available_calls

    def initialize(association: nil, options: {})
      super()
      @kanban_column = Column.new(association, options)
      @active_scaffold_config = Config.new([], KanbanConfig.new(nil, :status), SortableConfig.new(nil), Model)
      @available_calls = 0
      @kanban_view = false
    end

    def override_helper_per_model(method, _model)
      method == :kanban_columns ? :model_kanban_columns : :model_enum_options
    end

    def model_kanban_columns
      @available_calls += 1
      [['Backlog', :backlog]]
    end

    def model_enum_options(_column, _record)
      [['New', :new], %w[Done done]]
    end

    def active_scaffold_translated_option(_column, text, value)
      ["Translated #{text}", value]
    end

    def sorted_association_options_find(_association, _conditions, _record)
      [AssociationRecord.new(1, 'Backlog'), AssociationRecord.new(2, 'Done')]
    end

    attr_writer :kanban_view
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

  def test_available_columns_use_model_override_and_are_cached
    helper = SourceHelper.new

    assert_equal [['Backlog', :backlog]], helper.available_kanban_columns
    assert_equal [['Backlog', :backlog]], helper.available_kanban_columns
    assert_equal 1, helper.available_calls
  end

  def test_enum_columns_are_translated_and_symbol_values_are_strings
    helper = SourceHelper.new

    assert_equal [['Translated New', 'new'], ['Translated Done', 'done']], helper.kanban_columns
  end

  def test_association_columns_use_configured_label_method
    helper = SourceHelper.new(association: Association.new(:status), options: {label_method: :name})

    assert_equal [['Backlog', SourceHelper::AssociationRecord.new(1, 'Backlog')],
                  ['Done', SourceHelper::AssociationRecord.new(2, 'Done')]], helper.kanban_columns
  end

  def test_association_columns_default_to_record_label
    helper = SourceHelper.new(association: Association.new(:status))

    assert_equal ['Label Backlog', 'Label Done'], helper.kanban_columns.map(&:first)
  end

  def test_columns_are_not_receive_only_by_default
    refute SourceHelper.new.kanban_column_receive_only?(:done)
  end

  def test_member_link_position_is_replaced_in_kanban_view
    helper = SourceHelper.new
    helper.kanban_view = true
    helper.active_scaffold_config.kanban.define_singleton_method(:links_position) { :bottom }

    options = helper.action_link_html_options(Link.new(:member, :after), Object.new, {})

    assert_equal({data: {position: :bottom}, inherited: true}, options)
  end

  def test_non_member_link_options_are_left_unchanged
    helper = SourceHelper.new
    helper.kanban_view = true

    assert_equal({data: {}, inherited: true},
                 helper.action_link_html_options(Link.new(:collection, :after), Object.new, {}))
  end
end
