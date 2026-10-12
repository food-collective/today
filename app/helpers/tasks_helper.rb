module TasksHelper
  SECTION_TITLES = {
    3 => 'Do these first',
    2 => 'Assigned to you in Airtable',
    1 => 'When you have time'
  }.freeze

  def task_section_title(priority)
    SECTION_TITLES.fetch(priority) { 'Other tasks' }
  end

  def task_card_class(task)
    classes = ['task']
    classes << 'task--done' if task.completed
    classes << 'task--hot' if !task.completed && task.priority == 3
    classes << 'task--airtable' if !task.completed && task.category == 'Airtable'
    classes.join(' ')
  end

  # Airtable descriptions are stored as HTML (rendered from Markdown when they
  # were imported). Hand-written descriptions are plain text.
  def task_description(task)
    return '' if task.description.blank?

    if task.category == 'Airtable'
      sanitize(task.description)
    else
      simple_format(h(task.description), {}, wrapper_tag: 'p')
    end
  end

  def task_added_line(task)
    parts = []
    parts << "Added by #{task.user_add}" if task.user_add.present?
    parts << "#{time_ago_in_words(task.added)} ago" if task.added
    parts.join(' · ')
  end

  def task_done_line(task)
    return '' unless task.complete_time

    who = task.user_complete.presence || 'someone'
    when_text = if task.complete_time.to_date == Time.zone.today
                  "today at #{task.complete_time.strftime('%-l:%M %p')}"
                else
                  task.complete_time.strftime('%a %b %-d, %-l:%M %p')
                end
    "Done by #{who} #{when_text}"
  end

  # Turns an Airtable description (written in Markdown) into safe HTML.
  def airtable_markdown(text)
    return '' if text.blank?

    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
    sanitize Redcarpet::Markdown.new(renderer, autolink: true, tables: true).render(text)
  end
end
