ActiveScaffold.update_positions = function(content) {
  if (typeof(content) == 'string') content = jQuery('#' + content);
  var element = content.closest('.sortable-container');
  jQuery.each(content.find('.sub-form-record input[name$="[' + element.data('column') + ']"]'), function(i, field) {
    jQuery(field).val(i+1); // don't use 0
  });
}
ActiveScaffold.kanban = function(container) {
  jQuery.each(jQuery('.kanban', container), function(i, kanban) {
    kanban = jQuery(kanban);

    var revert = function(item) {
      var prev = jQuery(item).data('prev_card');
      if (prev.length) prev.after(item);
      else jQuery(item).data('prev_column').find('.cards').prepend(item);
    };
    var reorder_info = function(column) {
      var kanban = column.closest('.kanban');
      return column.sortable('serialize', {
        key: encodeURIComponent(kanban.data('reorder-key') + '[]'),
        expression: new RegExp(kanban.data('format'))
      });
    }

    var reorder_url = kanban.data('reorder-url'),
      change_url = kanban.data('change-url'),
      options = {
        connectWith: '.active-scaffold .kanban .kanban-column .cards',
        cancel: '.kanban-column[data-receive-only] .card',
        start: function(event, ui) {
          ui.item.data('prev_column', ui.item.closest('.kanban-column'))
            .data('prev_card', ui.item.prev());
        },
        beforeStop: function(event, ui) {
          event.handleObj.data = jQuery.extend(event.handleObj.data, {column_changed: ui.item.closest('.cards').get(0) !== this});
          if (!reorder_url) ui.item.cancel = !event.handleObj.data.column_changed;
        },
        update: function(event, ui) {
          if (ui.item.cancel) jQuery(this).sortable('cancel');
          else if (!event.handleObj.data || !event.handleObj.data.column_changed) {
            jQuery.ajax({
              url: reorder_url,
              data: reorder_info(jQuery(this)),
              method: 'POST',
              context: ui.item,
              error: function(xhr, status, error) {
                if (xhr.status >= 400) revert(this);
              }
            });
          }
        },
        over: function(event, ui) {
          jQuery(this).addClass('ui-highlight');
        },
        out: function(event, ui) {
          jQuery(this).removeClass('ui-highlight');
        },
        receive: function(event, ui) {
          var $this = jQuery(this), id = ui.item.data('value'),
            column_value = $this.closest('.kanban-column').data('value'),
            data = {value: column_value};
          if (jQuery.rails.fire(ui.item, 'kanban:beforeChange', {id: id, column: column_value})) {
            jQuery.extend(data, ui.item.data('params') || {});
            if (reorder_url) data = jQuery.param(data) + '&' + reorder_info($this);
            jQuery.ajax({
              url: change_url.replace('--ID--', id),
              data: data,
              method: 'POST',
              context: ui.item,
              error: function(xhr, status, error) {
                if (xhr.status >= 400) revert(this);
              }
            });
          } else revert(ui.item);
        }
      };
    kanban.find('.kanban-column .cards').sortable(options);
    return;
    if (url) {
      var csrf = jQuery('meta[name=csrf-param]').attr('content') + '=' + jQuery('meta[name=csrf-token]').attr('content');
      sortable_options.update = function(event, ui) {
        var $this = jQuery(this),
          body = $this.sortable('serialize',{key: encodeURIComponent(($this.data('key') || $this.attr('id')) + '[]'), expression: new RegExp(element.data('format'))});
        var params = element.data('with');
        if (params) body += '&' + params;
        jQuery.post(url, body + '&' + csrf);
      };
    }
  });
};

jQuery(document).ready(function($) {
  $(document).on('as:action_success', 'a.as_action', function(e, action_link) {
    ActiveScaffold.kanban(action_link.adapter);
  });
  $(document).on('as:element_updated', function(e) {
    ActiveScaffold.kanban(e.target);
  });
  ActiveScaffold.kanban(document);
});
