# encoding: utf-8
class Event::ApplicationDecorator < ::ApplicationDecorator
  decorates 'event/application'
  
  decorates_association :event
  decorates_association :priority_1
  decorates_association :priority_2
  decorates_association :priority_3

  delegate :dates_info, :dates_full, :kind, :group, to: :event

  def labeled_link(group = nil)
    group ||= event.groups.first
    event.labeled_link(h.group_event_participation_path(group, event, participation)) if can?(:show, participation)
  end
  
  def contact
    c = model.contact
    "#{c.class.base_class.name}Decorator".constantize.decorate(c)
  end
  
  def priority(event)
    prio = model.priority(event)
    if prio
      prio = "Prio #{prio}"
    else
      prio = waiting_list? ? 'Warteliste' : nil
    end
    content_tag(:span, prio, class: 'badge') if prio
  end
  
  def confirmation
    confirmation_badge(*confirmation_fields)
  end
  
  def confirmation_label
    label, css, desc = confirmation_fields
    confirmation_badge(label, css, desc) +
    " Kursfreigabe #{desc}"
  end
  
  def confirmation_badge(label, css, desc)
    content_tag(:span, label.html_safe, class: "badge badge-#{css}", title: "Kursfreigabe #{desc}")
  end
  
  private
  
  
  
  def confirmation_fields
    if approved?
      %w(&#x2713; success bestätigt)
    elsif rejected?
      %w(&#x00D7; important abgelehnt)
    else
      %w(? warning ausstehend)
    end
  end

end
  
