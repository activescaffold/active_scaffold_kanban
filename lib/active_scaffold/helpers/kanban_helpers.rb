module ActiveScaffold
  module Helpers
    module KanbanHelpers
      def kanban_columns
        record = active_scaffold_config.model.new
        if @kanban_column.association
          sorted_association_options_find(@kanban_column.association, nil, record).map do |record_column|
            [record_column.send(@kanban_column.options[:label_method] || :to_label), record_column]
          end
        else
          enum_options_method = override_helper_per_model(:active_scaffold_enum_options, record.class)
          send(enum_options_method, @kanban_column, record).collect do |text, value|
            text, value = active_scaffold_translated_option(@kanban_column, text, value)
            value = value.to_s if value.is_a? Symbol
            [text, value]
          end
        end
      end

      def kanban_column_receive_only?(column_value)
        false
      end

      def kanban_description(record)
        record.send(active_scaffold_config.kanban.description_method) if active_scaffold_config.kanban.description_method
      end

      def kanban_data_attrs
        attrs = {
          change_url: url_for(params_for(action: :update_column, id: '--ID--', column: active_scaffold_config.kanban.group_by_column)),
          format: '^[^_-](?:[A-Za-z0-9_-]*)-(.*)-row$',
          reorder_key: active_scaffold_tbody_id
        }
        if active_scaffold_config.actions.include?(:sortable) && active_scaffold_config.sortable.column
          attrs[:reorder_url] = url_for(params_for(action: :reorder, id: nil))
        end
        attrs
      end

      def action_link_html_options(link, record, options)
        options = super
        if @kanban_view && link.position == :after
          options[:data][:position] = :replace
        end
        options
      end
    end
  end
end