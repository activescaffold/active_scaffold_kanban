# frozen_string_literal: true

module ActiveScaffold
  module Config
    class Kanban < Base
      self.crud_type = :read

      def initialize(core_config)
        super
        @title_method = self.class.title_method
        @description_method = self.class.description_method
        @replace_list_view = self.class.replace_list_view
      end

      # global level configuration
      # --------------------------
      # the model's method used for card's title
      cattr_accessor :title_method, instance_accessor: false
      @@title_method = :to_label

      # the model's method used for card's description, set to nil for no description
      cattr_accessor :description_method, instance_accessor: false

      # enable it to replace list view with kanban, instead of being optional with view=kanban param
      cattr_accessor :replace_list_view, instance_accessor: false

      # the model's method used for card's title
      attr_accessor :title_method

      # the model's method used for card's description, set to nil for no description
      attr_accessor :description_method

      # enable it to replace list view with kanban, instead of being optional with view=kanban param
      attr_accessor :replace_list_view

      # the model's column used for kanban columns
      attr_accessor :group_by_column

      UserSettings.class_eval do
        user_attr :title_method, :description_method, :group_by_column, :replace_list_view
      end
    end
  end
end
