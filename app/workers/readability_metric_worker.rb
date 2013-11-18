class ReadabilityMetricWorker < GenericMetricWorker

  def perform(repository, snapshot, metric)
    @repository ||= Repository.find(repository)
    @snapshot ||= @repository.snapshots.where(date: snapshot).first

    @metadata ||= MetadataRecord.where(snapshot: @snapshot)
    @metadata = @metadata.only("record.notes", "record.resources.description")

    @metric = Metrics::Readability.new('en_us')
    super
  end

end