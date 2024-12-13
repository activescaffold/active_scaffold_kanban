# frozen_string_literal: true

module ActiveScaffold
  module Actions
    module Kanban
      def self.included(base)
        base.before_action :setup_kanban, only: [:index, :update_column, :reorder, :create]
        base.after_action :reorder_cards, only: :update_column
        base.after_action :set_error_status_code, only: [:update_column, :reorder]
      end

      protected

      def setup_kanban
        return unless params[:view] == 'kanban' || active_scaffold_config.kanban.replace_list_view
        @kanban_view = true
        @kanban_column = active_scaffold_config.columns[active_scaffold_config.kanban.group_by_column]
        active_scaffold_config.list.pagination = nil
      end

      def reorder_cards
        reorder if successful? && active_scaffold_config.actions.include?(:sortable) && ordered_ids
      end

      def set_error_status_code
        response.status = 400 unless successful?
      end
    end
  end
end
