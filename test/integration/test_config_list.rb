# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/object/blank'

module ActiveScaffold
  module Actions
  end

  module Helpers
  end
end

require 'active_scaffold/actions/config_list'
require 'active_scaffold/helpers/config_list_helpers'

require_relative '../../lib/active_scaffold_kanban/config_list'

class KanbanConfigListTest < Minitest::Test
  ConfigListConfig = Struct.new(:save_to_user, :global_views)
  ListConfig = Struct.new(:user)
  Config = Struct.new(:config_list, :list)

  class Action
    def self.before_action(*); end

    def self.helper_method(*); end

    include ActiveScaffold::Actions::ConfigList
    prepend ActiveScaffoldKanban::ConfigListAction

    attr_reader :active_scaffold_config, :params, :storage

    def initialize
      @params = {}
      @storage = {}
      @kanban_view = true
      @active_scaffold_config = Config.new(ConfigListConfig.new(nil, false), ListConfig.new({}))
    end

    def active_scaffold_session_storage
      @storage
    end

    def active_scaffold_session_storage_key
      'tasks'
    end

    def controller_name
      'tasks'
    end

    def active_scaffold_current_user
      nil
    end

    public :config_list_controller_name, :config_list_session_storage,
           :config_list_session_storage_key, :delete_config_list_params, :save_config_list_params
  end

  class Helper
    include ActiveScaffold::Helpers::ConfigListHelpers
    prepend ActiveScaffoldKanban::ConfigListHelpers

    Value = Struct.new(:id)
    Column = Struct.new(:association)

    def initialize(association: false)
      super()
      @kanban_view = true
      @kanban_column = Column.new(association)
    end

    def user_kanban_columns
      [['Done', Value.new(2)]]
    end

    def available_kanban_columns
      [['Backlog', Value.new(1)], ['Done', Value.new(2)]]
    end
  end

  class BaseNonKanbanHelper
    def config_list_sorting?
      true
    end

    def config_list_columns
      [:base_columns]
    end
  end

  class NonKanbanHelper < BaseNonKanbanHelper
    prepend ActiveScaffoldKanban::ConfigListHelpers
  end

  def test_kanban_uses_distinct_storage_identity
    action = Action.new

    assert_equal 'tasks:kanban', action.config_list_session_storage_key
    assert_equal 'tasks:kanban', action.config_list_controller_name
  end

  def test_kanban_reads_and_creates_nested_session_storage
    action = Action.new

    assert_equal({}, action.config_list_session_storage)
    action.save_config_list_params(%w[title status], nil, nil, nil)

    assert_equal(
      {'kanban' => {'config_list' => %i[title status], 'config_list_sorting' => nil}},
      action.storage
    )
    assert_equal %i[title status], action.config_list_session_storage['config_list']
  end

  def test_deleting_kanban_configuration_removes_nested_storage
    action = Action.new
    action.save_config_list_params(%w[title status], nil, nil, nil)

    action.delete_config_list_params(nil)

    assert_equal({}, action.storage)
    assert_equal({}, action.config_list_session_storage)
  end

  def test_kanban_disables_list_sorting_configuration
    assert_nil Helper.new.config_list_sorting?
  end

  def test_config_list_columns_keep_selected_order_then_append_remaining_columns
    helper = Helper.new(association: true)

    assert_equal [['Done', :'2'], ['Backlog', :'1']], helper.config_list_columns
  end

  def test_normal_list_uses_original_sorting_and_columns
    helper = NonKanbanHelper.new

    assert helper.config_list_sorting?
    assert_equal [:base_columns], helper.config_list_columns
  end
end
