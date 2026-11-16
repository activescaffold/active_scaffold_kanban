# frozen_string_literal: true

require 'test_helper'

class KanbanConfigTest < Minitest::Test
  class Core
    def model_id
      :task
    end
  end

  def setup
    @config = ActiveScaffold::Config::Kanban.new(Core.new)
  end

  def test_defaults_are_copied_to_each_configuration
    assert_equal :to_label, @config.title_method
    assert_nil @config.description_method
    assert_nil @config.replace_list_view
    assert_equal :table, @config.links_position
  end

  def test_instance_settings_can_be_overridden
    @config.title_method = :name
    @config.description_method = :summary
    @config.group_by_column = :status
    @config.replace_list_view = true
    @config.links_position = :after

    assert_equal :name, @config.title_method
    assert_equal :summary, @config.description_method
    assert_equal :status, @config.group_by_column
    assert @config.replace_list_view
    assert_equal :after, @config.links_position
  end

  def test_kanban_uses_read_authorization
    assert_equal :read, ActiveScaffold::Config::Kanban.crud_type
  end
end
