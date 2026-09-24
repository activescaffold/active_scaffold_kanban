# Kanban for ActiveScaffold

ActiveScaffold Kanban renders scaffold records as cards grouped into board columns. Moving a card to another board column updates the configured model attribute or association, and optional sortable integration persists the order of cards within each column.

## Requirements

- Active Scaffold 3.7.11 or newer
- ActiveScaffold Sortable 3.2.2 or newer
- ActiveScaffold Config List 3.6.0 or newer

Sortable and Config List are runtime dependencies and are installed with the Kanban gem. Their actions are enabled per scaffold only when their corresponding features are needed.

## Installation

Add the gem to your `Gemfile`:

```ruby
gem 'active_scaffold_kanban'
```

Then run `bundle install`.

## Basic configuration

Enable `:kanban` and select the database column or association used to group the cards:

```ruby
class TasksController < ApplicationController
  active_scaffold :task do |config|
    config.actions << :kanban
    config.kanban.group_by_column = :status
  end
end
```

Open the index with `?view=kanban` to display the board. To make the board the scaffold's default index view instead, set:

```ruby
config.kanban.replace_list_view = true
```

Pagination is disabled while rendering the Kanban view so that all records in the current result set can be placed on the board.

## Board columns

The `kanban_columns` helper returns the available board columns as `[label, value]` pairs. By default it resolves values in the same way as a column using the `:select` form UI:

- For a regular model column, set `config.columns[:status].options[:options]` or override `active_scaffold_enum_options`.
- For an association, use `options_for_association_conditions` or `association_klass_scoped` to restrict the available associated records. The association column's `label_method` controls their labels.

These helper overrides support the model-name prefix. You can also replace the complete board-column list:

```ruby
module TasksHelper
  def task_kanban_columns
    [['Backlog', 'backlog'], ['In progress', 'started'], ['Done', 'done']]
  end
end
```

For an association, the second item in each pair must be the associated record rather than its ID.

## Moving and ordering cards

Dragging a card to another board column calls Active Scaffold's `update_column` action to update `group_by_column`, using the same save and authorization path as in-place editing. If the update fails, the request returns an error and the card moves back to its original position.

Cross-column moves work without enabling the `:sortable` action, but card order is not persisted. Reordering within the same board column is disabled, and the apparent position of a card moved to another column may change when the board reloads.

To persist card order, enable Sortable and configure its position column:

```ruby
active_scaffold :task do |config|
  config.actions << :kanban
  config.kanban.group_by_column = :status

  config.actions << :sortable
  config.sortable.column = :position
end
```

With this configuration, a move within one board column calls the Sortable `reorder` action. A move between columns updates the grouping value through `update_column` and then persists the submitted order.

## Receive-only columns

A board column can accept cards while preventing its existing cards from being dragged out. Override `kanban_column_receive_only?`; it receives the board-column value, which is the associated record when `group_by_column` is an association:

```ruby
module TasksHelper
  def task_kanban_column_receive_only?(status)
    status == 'done'
  end
end
```

This helper also supports the model-name prefix, as shown above.

## Config List integration

When the scaffold also enables `:config_list`, users can choose which board columns are visible and arrange their order:

```ruby
config.actions << :config_list
```

Kanban column preferences are stored separately from the ordinary list-column configuration. List sorting settings are not applied to board columns.

## Card content and actions

Configure the model methods used for card content:

```ruby
config.kanban.title_method = :name       # default: :to_label
config.kanban.description_method = :summary
```

No description content is shown by default. To customize only the description markup, override `kanban_description(record)` or its model-prefixed form, such as `task_kanban_description(record)`.

To replace the complete card markup, override `_kanban_card.html.erb` in the controller's view directory, for example `app/views/tasks/_kanban_card.html.erb`.

Cards render the scaffold's normal member action links. Inline links whose normal position is `:before`, `:after`, or `:replace` use `config.kanban.links_position`, which defaults to `:table`, while the board is active. An action link can be hidden from the board by assigning an `ignore_method` that checks `@kanban_view`, or by overriding `skip_action_link?`.

The normal create action also works from the Kanban view. After a successful create, the new card is inserted into the board column matching its `group_by_column` value.

## Global defaults

The title method, description method, default-view behavior, and link position can be configured for every Kanban scaffold before controller configurations are built:

```ruby
ActiveScaffold::Config::Kanban.title_method = :name
ActiveScaffold::Config::Kanban.description_method = :summary
ActiveScaffold::Config::Kanban.replace_list_view = true
ActiveScaffold::Config::Kanban.links_position = :table
```

`group_by_column` must still be configured for each scaffold.

## JavaScript hook

Before a card moves to a different board column, the plugin fires `kanban:beforeChange` on the card. The handler receives an object containing `id` (the record ID) and `column` (the destination value, or the associated record ID for an association).

Return `false` to reject the move. Extra parameters placed in the card's `params` data are merged into the `update_column` request:

```javascript
$(document).on('kanban:beforeChange', '.kanban .card', function(event, data) {
  if (data.column === 'done' && !window.confirm('Mark this task as done?')) {
    return false;
  }

  $(this).data('params', { changed_from: 'kanban' });
});
```

## License

Released under the MIT License.
