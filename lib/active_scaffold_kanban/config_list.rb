# frozen_string_literal: true

module ActiveScaffoldKanban
  module ConfigListAction
    def config_list_session_storage_key
      @kanban_view ? "#{super}:kanban" : super
    end

    def config_list_controller_name
      @kanban_view ? "#{super}:kanban" : super
    end

    def config_list_session_storage(root: false)
      storage = super()
      return storage if root || !@kanban_view

      storage['kanban'] || {}
    end

    def delete_config_list_params(...)
      super
      config_list_session_storage(root: true).delete 'kanban' if @kanban_view
    end

    def save_config_list_params(...)
      config_list_session_storage(root: true)['kanban'] ||= {} if _as_use_session_for_kanban?
      super
    end

    def _as_use_session_for_kanban?
      return false if active_scaffold_config.config_list.save_to_user && active_scaffold_current_user

      !!@kanban_view
    end
    private :_as_use_session_for_kanban?
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
