module MetricsHelper

  ##
  # Constructs an entry for the record selector based on a given document.
  #
  # The +current+ document is used to find the document to replace for the new
  # link. The +new+ document is used for the menu item text and the link.
  #
  def record_selector_entry(current, new)
    score = "%6.2f%" % (new[@metric.id]['score'] * 100)
    score = score.gsub(' ', '&nbsp;')

    text = "#{score} &#8212; #{new.record['name']}".html_safe
    href = record_selector_entry_link(current, new)

    anchor = content_tag(:a, text, role: 'menuitem', tabindex: '-1', href: href)
    content_tag(:li, anchor, role: 'presentation')
  end

  ##
  # Constructs the link for an entry of the record selector
  #
  def record_selector_entry_link(current, new)
    documents = @documents.map { |document| document.id }
    documents[documents.index(current.id)] = new.id

    query = documents.map do |document|
      URI.unescape(document.to_query(:"documents[]"))
    end * '&'
    "?#{query}"
  end

  ##
  # Titlize record field names.
  #
  def titleize_ckan_field(field)
    defined = { 'url' => 'URL',
                'webstore_url' => 'Webstore URL',
                'cache_url' => 'Cache URL',
                'mimetype' => 'MIME Type',
                'mimetype_inner' => 'MIME Type (Inner)',
                'owner_org' => 'Owner Organization' }

    return defined[field] if defined.key?(field)

    field.titleize()
  end

  def highlight_misspellings(analysis, i)
    accessor = analysis[:field]
    value = html_escape(Metrics::Metric.value(@documents[i].record, accessor))

    analysis[:misspelled].each do |misspelling|
      span = content_tag(:span, misspelling, class: 'misspelled')
      value = value.gsub(misspelling, span)
    end

    value.html_safe unless value.nil?
  end

  def repository_metric_repository_menu
    locals = { display: @repository.name,
               entities: @repositories,
               :parameter => :repository_id,
               :path => :repository_snapshot_metric_path }

    partial = render partial: 'shared/dropdown_menu', locals: locals
    content_tag(:li, partial, class: 'repository selector')
  end

  def repository_metric_snapshot_menu
    locals = { display: @snapshot.date,
               entities: @repository.snapshots,
               :parameter => :snapshot_id,
               :path => :repository_snapshot_metric_path }

    partial = render partial: 'shared/dropdown_menu', locals: locals
    content_tag(:li, partial, class: 'repository selector')
  end

  def repository_metric_metric_menu
    locals = { display: @metric.to_s.titleize,
               entities: Metrics::Metric.all.map { |m| Metrics.from_sym(m) },
               :parameter => :id,
               :path => :repository_snapshot_metric_path }

    partial = render partial: 'shared/dropdown_menu', locals: locals
    content_tag(:li, partial, class: 'repository selector')
  end

  def description
    description = Metrics.from_sym(@metric).description

    text = "[Missing Description]"
    text = "&ldquo;#{description}&rdquo;" unless description.nil?
    
    content_tag(:p, text.html_safe, class: 'description')
  end

  def record_selection_entry(range, i)
    anchor_data = { toggle: 'modal', range: "#{range}-#{range + 10}", document: i }
    anchor_attributes = { role: 'menuitem', tabindex: '-1', href: "#search-by-score-#{i}", data: anchor_data }

    entry_label = "Score %3.f - %3.f" % [range, range + 10]
    entry_label = "Score %4.f - %3.f" % [range, range + 10] if range == 0
    entry_label = entry_label.gsub!(' ', '&nbsp;').html_safe

    content_tag(:li, content_tag(:a, entry_label, anchor_attributes))
  end

  def display_field(field_path)
    if field_path.last.is_a?(Numeric)
      number = field_path.last
      field_path[0..-2].join('.') + " (#{number})"
    else
      field_path.join('.')
    end
  end

end
