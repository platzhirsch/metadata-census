class LinkCheckerMetricWorker <  MetricsWorker

  def perform(repository_name)
    logger.info('Loading metadata')
    repository = Repository.find(repository_name)
    @metadata = repository.metadata
    logger.info('Preprocessing metadata')
    metric = Metrics::LinkChecker.new(@metadata, self)
    compute(repository, metric)
  end

end
