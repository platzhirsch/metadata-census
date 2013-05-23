class MetricsController < ApplicationController

  def overview
    preprocess
  end

  def preprocess
    @repositories = Repository.all
    if params[:repository].nil?
      @selected = @repositories.first if @selected.nil?
    else
      @selected = Repository.find params[:repository]
    end
    gon.repository = @selected.to_hash
  end

  def accuracy_stats
    preprocess
    stats = Hash.new 0

    repository = params[:repository]
    if repository.nil?
      repository = @selected
    else
      repository = Repository.find repository
    end

    size = 0.0
    metadata = all_metadata(repository)
    metadata.each do |document|
      document[:resources].each do |resource|
        format = resource[:format]
        format = resource[:mimetype] unless resource[:mimetype].nil?
        next if format.nil?
        size += 1
        stats[format.downcase] += 1
      end
    end
    stats = stats.inject([]) do |result, item|
      result << { "format" => item[0],
                  "frequency" => item[1] / size }
    end
    gon.data = stats
  end

  def compute
    repository_name = params[:repository]
    metric = params[:metric]

    repository = Repository.find repository_name

    case metric
    when 'completeness'
      CompletenessMetricWorker.perform_async(repository_name)
    when 'weighted-completeness'
      WeightedCompletenessMetricWorker.perform_async(repository_name)
    when 'richness-of-information'
      RichnessOfInformationMetricWorker.perform_async(repository_name)
    when 'accuracy'
      AccuracyMetricWorker.perform_async(repository_name)
    when 'accessibility'
      AccessibilityMetricWorker.perform_async(repository_name)
    end

    render :text => '☠'
  end

end
