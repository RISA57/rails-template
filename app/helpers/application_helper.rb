module ApplicationHelper
  def mark_required
    content_tag(:span, '*', class: 'required')
  end

  def flash_messages
    flash.map do |level, message|
      content_tag(:div, class: "alert alert-#{message_level(level)}") do
        content_tag(:p, message, class: 'message')
      end
    end.join(' ').html_safe
  end

  def error_messages(*objects)
    messages = objects.compact.map { |o| o.errors.full_messages }.flatten
    _error_messages(messages)
  end

  def error_messages_for_service(object)
    _error_messages(object.errors.uniq) if object
  end

  def _error_messages(messages)
    if messages.present?
      content_tag(:div, class: "alert alert-#{message_level :error}") do
        list_items = messages.map { |m| content_tag(:li, m) }
        content_tag(:ul, list_items.join.html_safe, class: 'list-unstyled')
      end
    end
  end

  # Twitter Bootstrap用にクラス名を変換する
  def message_level(level)
    case level.to_sym
    when :notice then :success
    when :alert then :warning
    when :error then :danger
    end
  end

  def body_class
    qualified_controller_name = controller.controller_path.gsub('/','-')
    "#{qualified_controller_name}-#{controller.action_name}"
  end
end
