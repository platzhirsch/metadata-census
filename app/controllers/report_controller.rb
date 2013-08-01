class ReportController < ApplicationController
  helper_method :metric_score

  def repository
    @repositories = Repository.all
    @repository = params[:show] || @repositories.first.name
    @repository = Repository.find(@repository)
    @score = average_score(@repository)
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

end
