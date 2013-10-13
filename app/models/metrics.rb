module Metrics

  def self.all
    initialize if Rails.env.development?
    initialize_once if Rails.env.production?

    cls = Metrics::Metric
    cls.metrics
  end

  ## Eager load all metric classes
  # 
  # In development environment the metric classes are wiped per request. This
  # method helps to manually load them.
  #
  def self.initialize
    directory = self.to_s.downcase
    path = Rails.root.join("app/models/#{directory}/*.rb")
    Dir[path].each { |metric_file| load metric_file }
  end

  def self.initialize_once
    initialize unless defined? @initialized
    @initialized ||= true
  end

  def self.normalize(metric, values)
    metric = metric.to_sym
    return values unless self.from_sym(metric).normalize?
  
    scores = Array(values)
    repositories = Repository.all

    repositories.each do |repository|
      score = repository.snapshots.last.maybe(metric)

      unless score.nil?
        scores << score['minimum']
        scores << score['maximum']
      end
    end

    min = scores.min
    max = scores.max
    range = max - min

    return (values - min) / range unless values.is_a?(Array)
    values.map { |value| (value - min) / range }
  end

  def self.from_sym(symbol)
    "#{self.name}::#{symbol.to_s.underscore.camelcase}".constantize
  end

  def self.url(metric)
    metric.to_s.gsub('_', '-')
  end

  def self.blank?(value)
    value.nil? || value.is_a?(Boolean) || value.is_a?(Fixnum) ||
      value.empty? || (value.is_a?(String) && value !~ /[^[:space:]]/)
  end

end
