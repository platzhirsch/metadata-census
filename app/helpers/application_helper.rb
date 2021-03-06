module ApplicationHelper

  def navbar_button(display, path, icon=nil)
    cls = current_page?(path) ? 'active' : nil
    display = tag(:span, class: icon) + " " + display
    content_tag(:li, link_to(display.html_safe, path), class: cls)
  end

  def score_presentation(snapshot, metric)
    score = snapshot.send(metric.id).maybe['average']
    return '-' if score.nil?

    '%.2f' % score
  end

  def repository_menu
    locals = { display: @repository.name,
               entities: @repositories.keys,
               :parameter => :id,
               :path => :repository_path,
               :id => :id }

    partial = render partial: 'shared/dropdown_menu', locals: locals
    content_tag(:li, partial, class: 'repository selector')
  end

  def snapshot_menu
    locals = { display: @snapshot.date,
               entities: @repository.snapshots,
               :parameter => :id,
               :path => :repository_snapshot_path,
               :id => :date }

    partial = render partial: 'shared/dropdown_menu', locals: locals
    content_tag(:li, partial, class: 'repository selector')
  end

end
