# frozen_string_literal: true

module ActiveScaffoldKanban
  module ConfigListAction
    def config_list_session_storage_key
      @kanban_view ? "#{super}:kanban" : super
    end

    def config_list_session_storage(storage = false)
      if @kanban_view
        hsh = super()
        return hsh if storage
        hsh['kanban'] || {}
      else
        super()
      end
    end

    def delete_config_list_params
      super
      config_list_session_storage(true).delete 'kanban' if @kanban_view
    end

    def save_config_list_params(...)
      unless active_scaffold_config.config_list.save_to_user && active_scaffold_current_user
        config_list_session_storage(true)['kanban'] ||= {} if @kanban_view
      end
      super
    end
  end

  module ConfigListHelpers
    def config_list_sorting?
      super unless @kanban_view
    end

    def config_list_columns
      if @kanban_view
        columns = user_kanban_columns # get selected columns first, to keep sorting
        columns += available_kanban_columns - columns # add not selected columns if user has selected some
        columns.map do |label, value|
          [label, (@kanban_column.association ? value.id : value).to_s.to_sym]
        end
      else
        super
      end
    end
  end
end
