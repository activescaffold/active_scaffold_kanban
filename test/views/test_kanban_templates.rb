# frozen_string_literal: true

require 'erb'
require 'test_helper'

class KanbanTemplatesTest < Minitest::Test
  Column = Struct.new(:name, :association)
  KanbanConfig = Struct.new(:title_method)
  ListConfig = Struct.new(:messages_above_header)
  ActionLinks = Struct.new(:member)
  Config = Struct.new(:kanban, :list, :action_links, :model)
  Record = Struct.new(:id, :status, :title)

  class View
    attr_accessor :insert_at, :kanban_view, :successful
    attr_reader :active_scaffold_config, :render_calls

    def initialize(kanban_view: true, successful: true, messages_above_header: true)
      @kanban_view = kanban_view
      @successful = successful
      @active_scaffold_config = Config.new(
        KanbanConfig.new(:title),
        ListConfig.new(messages_above_header),
        ActionLinks.new([:edit]),
        Record
      )
      @kanban_column = Column.new(:status, nil)
      @record = Record.new(3, :backlog, 'Third task')
      @records = [@record, Record.new(4, :done, 'Fourth task')]
      @insert_at = :top
      @render_calls = []
    end

    def evaluate(template, locals = {})
      context = binding
      locals.each { |name, value| context.local_variable_set(name, value) }
      source = File.read(template_path(template))
      # Plain ERB cannot parse Rails' output block form; the yielded body already writes to its buffer.
      source = source.gsub('<%= content_tag', '<% content_tag') if template == '_kanban.html.erb'
      ERB.new(source).result(context)
    end

    def render(*arguments, **options)
      render_calls << [arguments, options]
      name = options[:partial] || arguments.first
      "rendered-#{name}"
    end

    def content_tag(tag, **_options)
      content = block_given? ? yield : ''
      "<#{tag}>#{content}</#{tag}>"
    end

    def override_helper_per_model(method, _model)
      method
    end

    def kanban_data_attrs
      {reorder_key: 'tasks'}
    end

    def user_kanban_columns
      [['Backlog', :backlog], ['Done', :done]]
    end

    def kanban_column_receive_only?(value)
      value == :done
    end

    def kanban_description(record)
      "Description #{record.id}"
    end

    def element_row_id(action:, id: nil)
      "#{action}-#{id || @record.id}-row"
    end

    def loading_indicator_tag(**)
      'loading'
    end

    def display_action_links(*, **)
      'actions'
    end

    def active_scaffold_id
      'tasks'
    end

    def escape_javascript(value)
      "escaped-#{value}"
    end

    def javascript_literal(value)
      value.inspect
    end

    def successful?
      successful
    end

    private

    def template_path(template)
      File.expand_path("../../app/views/active_scaffold_overrides/#{template}", __dir__)
    end
  end

  def test_kanban_renders_each_column_with_its_matching_records
    view = View.new

    output = view.evaluate('_kanban.html.erb')

    assert_includes output, 'Backlog'
    assert_includes output, 'Done'
    card_calls = view.render_calls.select { |_, options| options[:partial] == 'kanban_card' }
    assert_equal 2, card_calls.size
    assert_equal [3], card_calls.first.last[:collection].map(&:id)
    assert_equal [4], card_calls.last.last[:collection].map(&:id)
  end

  def test_kanban_card_renders_title_actions_and_description
    view = View.new
    record = Record.new(8, :done, 'Ship release')

    output = view.evaluate('_kanban_card.html.erb', record: record)

    assert_includes output, 'Ship release'
    assert_includes output, 'list-8-row'
    assert_includes output, 'loading'
    assert_includes output, 'actions'
    assert_includes output, 'Description 8'
  end

  def test_list_renders_kanban_and_messages
    view = View.new

    output = view.evaluate('_list.html.erb')

    assert_includes output, 'rendered-list_messages_content'
    assert_includes output, 'rendered-list_messages'
    assert_includes output, 'rendered-kanban'
  end

  def test_list_delegates_to_original_partial_outside_kanban
    view = View.new(kanban_view: false)

    assert_includes view.evaluate('_list.html.erb'), 'rendered-super'
  end

  def test_new_record_inserts_card_into_matching_column
    view = View.new

    output = view.evaluate('_new_record.js.erb', insert_at: :bottom)

    assert_includes output, 'ActiveScaffold.create_record_row'
    assert_includes output, 'rendered-kanban_card'
    assert_includes output, '.sortable(\'refresh\')'
  end

  def test_new_record_delegates_outside_kanban
    view = View.new(kanban_view: false)

    assert_includes view.evaluate('_new_record.js.erb'), 'rendered-super'
  end

  def test_successful_column_update_replaces_card
    view = View.new

    output = view.evaluate('update_column.js.erb')

    assert_includes output, 'ActiveScaffold.replace'
    assert_includes output, 'rendered-kanban_card'
  end

  def test_failed_column_update_does_not_replace_card
    view = View.new(successful: false)

    refute_includes view.evaluate('update_column.js.erb'), 'ActiveScaffold.replace'
  end

  def test_column_update_delegates_outside_kanban
    view = View.new(kanban_view: false)

    assert_includes view.evaluate('update_column.js.erb'), 'rendered-super'
  end
end
