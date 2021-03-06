require 'time'
require 'action_view'

##
# Base metric worker which all metric worker have to subclass.
#
class MetricWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include ActionView::Helpers::DateHelper

  def perform(repository, snapshot, metric, *args)
    scores = []
    store :stage => :compute
    logger.info('Compute metadata scores')

    @before = Time.now
    @metadata.each_with_index do |document, i|
      document[metric] = Hash.new if document[metric].nil?

      record = document.record
      score, analysis = @metric.compute(record, *args)

      document.send(metric)['score'] = score
      document.send(metric)['analysis'] = analysis

      document['score'] = document.calculate_score
      document.save!

      scores << score
      eta(i + 1, @metadata.length)
      at(i + 1, @metadata.length)
    end

    if Metrics.from_sym(metric).normalize?
      @metadata.each_with_index do |document, i|
        document.send(metric)['score'] = Metrics.normalize(scores, [document[metric]['score']]).first
        document['score'] = document.calculate_score
        document.save!
      end
      scores = Metrics.normalize(scores, scores)
    end

    update_snapshot(metric, scores)
  end

  def update_snapshot(metric, scores)
    snapshot = @snapshot
    score = Hash.new
    analysis = @metric.analysis

    scores = scores.reject(&:nan?)
    scores.sort!

    score['minimum'] = scores.first
    score['maximum'] = scores.last
    score['average'] = scores.inject(:+) / scores.length
    score['median'] = scores[scores.length / 2]

    snapshot[metric] = score
    snapshot[metric]['last_updated'] = DateTime.now.to_s
    snapshot[metric]['analysis'] = analysis

    snapshot.save!
  end

  def self.symbolize_keys arg
    case arg
    when Array
      arg.map { |elem| symbolize_keys elem }
    when Hash
      Hash[arg.map do |key, value|
        k = key.is_a?(String) ? key.to_sym : key
        v = symbolize_keys value
        [k,v]
      end]
    else
      arg
    end
  end

  ## Derive the metric worker class
  #
  # Uses +metric+ to dynamically retrieve the corresponding metric worker class
  # which is used to instantiate a new computation job. If there is no metric
  # worker matching the metric the default generic worker is returned.
  #
  def self.worker_class(metric)
    begin
      (metric.to_s.underscore.camelcase + "MetricWorker").constantize
    rescue NameError
      GenericMetricWorker
    end
  end

  def eta(i, steps)
    now = Time.now
    elapsed = now - @before
    time_per_step = elapsed / i

    estimate = time_per_step * (steps - i)
    store :eta => distance_of_time_in_words(now, now + estimate)
  end


end
