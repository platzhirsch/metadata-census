class SnapshotsController < ApplicationController
  include RepositoryManager
  include MetricManager

  helper_method :metric_score

  def index
    scores = @repositories.map { |repository| repository.score }
    filtered = scores.sort.uniq.reverse
    @ranking = scores.map { |score| filtered.index(score) + 1 }

    @numbers = Hash.new
    @languages = Set.new

    Repository.all.each do |repository|
      snapshot = repository.snapshots.last
      next if snapshot.nil? or snapshot.statistics.nil?

      @numbers[repository] = snapshot.statistics

      languages = @numbers[repository]['languages']
      @languages = @languages + languages.keys

      total = languages.values.sum
      languages.update(languages) { |language, count| count.fdiv(total) }
    end

    @languages.delete('Unknown').delete('Unreliable')
  end

  def score
    weighting = Hash.new
    @metrics.each do |metric|
      weighting[metric] = params[metric].to_i unless params[metric].nil?
    end
    render text: @repository.score(weighting)
  end

  def scores
    result = @metrics.each_with_object({}) do |metric, scores|
      scores[metric] = metric_score(metric)
    end
    render json: result
  end

  def leaderboard
    @repositories.to_a.sort! { |x, y| x.score <=> y.score }
  end

  def map
    @repositories = Repository.all
    gon.repositories = @repositories.map { |r| r.attributes }
  end

  def metric_score(metric, weighting=1.0)
    snapshot = @snapshot
    value = snapshot.maybe(metric)
    unless value.nil?
      value = value['average']
      '%.d%' % (value  * 100)
    else
      '-'
    end
  end

  def distribution
    analyzer = Analyzer::QualityDistribution.new
    distribution = Rails.cache.fetch(@snapshot) do
      analyzer.analyze(@snapshot)
    end
    render json: distribution
  end

  def statistics
    snapshot = @repository.snapshots.last
    @times = snapshot.statistics['times']
  end

  def metadata
    distribution = params[:distribution].to_i
    analyzer = Analyzer::QualityDistribution.new
    @distribution = analyzer.records(@snapshot, distribution)
  end

end
