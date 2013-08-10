class LinkCheckerMetricWorker <  MetricWorker

  def perform(repository, metric)
    store state: :load
    logger.info('Loading metadata')

    @repository ||= Repository.find(repository)
    @metadata ||= @repository.metadata

    store state: :analyze
    logger.info('Analyzing metadata')

    records = @metadata.map { |document| document[:record] }
    @metric = Metrics::LinkChecker.new(records, self)
    super
  end

end

