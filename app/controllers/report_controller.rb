class ReportController < ApplicationController
  include Concerns::Repository
  include Concerns::Metric

  helper_method :metric_score, :record, :metric_abbreviation

  def repository
    load_repositories(:show)
    @score = average_score(@repository)
  end

  def metric
    load_repositories(:repository)
    load_metrics(:show)

    @record1 = @repository.best_record(@metric)
    @record2 = @repository.worst_record(@metric)

    2.times do |i|
      parameter = "record#{i + 1}".to_sym
      unless params[parameter].nil?
        record = @repository.get_record(params[parameter])
        instance_variable_set("@record#{i + 1}", record)
      end
    end
  end

  def metric_score(metric)
    value = @repository.send(metric)
    unless value.nil?
      value = value[:average]
      value = Metrics::normalize(metric, [value]).first
      '%.2f' % (value  * 100)
    else
      ''
    end
  end

  def average_score(repository)
    metrics = Metrics::IDENTIFIERS
    sum = metrics.inject(0.0) do |sum, metric|
      score = repository.send(metric)
      unless score.nil?
        value = score[:average]
        if Metrics::NORMALIZE.include?(metric)
          value = Metrics::normalize(metric, [value]).first
        end
      else
        value = 0.0
      end

      sum + value
    end
    sum / metrics.length
  end

  def record(i)
    instance_variable_get("@record#{i + 1}")
  end

  def metric_abbreviation(metric)
    metric.to_s.split('_').inject('') do |abbreviation, word|
      abbreviation + word.first
    end.upcase
  end

end
