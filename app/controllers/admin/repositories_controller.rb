require 'oj'

class Admin::RepositoriesController < ApplicationController
  include RepositoryManager
  include MetricManager

  helper_method :repository_count

  def create
    file = params[:file]
    catalog = YAML.load_file(file).with_indifferent_access

    catalog[:repositories].each do |repository|
      attributes = attribute_hash(repository)
      repository = Repository.where(_id: attributes['_id'])

      if not repository.exists?
        repository = Repository.create!(attributes)
      else
        repository.first.update_attributes!(attributes)
      end
    end

    render nothing: true
  end

  def new
    @repository_files = repository_files()
    @metadata_archives = metadata_archives()
  end

  def compile
    controller = Admin::SnapshotsController.new

    if params[:target] == 'languages'
      Repository.all.each do |repository|
        repository.snapshots.each do |snapshot|
          logger.info("Compiling #{repository.name}")
          controller.compile_languages(snapshot)
          snapshot.save!
        end
      end
    elsif params[:target] == 'times'
      Repository.all.each do |repository|
        repository.snapshots.each do |snapshot|
          logger.info("Compiling #{repository.name}")
          controller.compile_times(snapshot)
          snapshot.save!
        end
      end
    else
      Repository.all.each do |repository|
        repository.snapshots.each do |snapshot|
          logger.info("Compiling #{repository.name}")
          controller.compile_statistics(snapshot)
          snapshot.save!
        end
      end
    end

    render nothing: true
  end

  ##
  # Returns a list of available YAML files containing repositories to import.
  #
  def repository_files
    files = Dir.glob('data/repositories/*.yml').select { |f| File.file?(f) }
    files.map do |yaml| 
      { yaml => YAML.load_file(yaml).with_indifferent_access }
    end.reduce(:merge)
  end

  ##
  # Returns a list of available metadata archives.
  #
  def metadata_archives
    archives = Dir.glob('data/archives/**/*.gz').select { |f| File.file?(f) }

    init = Hash.new { |hash, key| hash[key] = [] }
    archives.inject(init) do |result, archive|
      header = parse_header(archive)
      header['file'] = archive
      header['repository'] = header['repository'].downcase
      result[header['repository']] << header
      result
    end
  end

  ##
  # Parses the meta-metadata from the archive in a stream-based fashion.
  #
  def parse_header(file)
    file = File.new(file, 'r')
    reader = Zlib::GzipReader.new(file)
    Oj.load(reader.readline)
  end

  def repository_count(yaml)
    yaml.except(:name).values.map(&:length).reduce(:+)
  end

  private

  ##
  # Returns hash of valid attributes which can be used to create a new
  # +Repository+ object.
  #
  def attribute_hash(repository_hash)
    id = repository_hash.delete('id')
    raise TypeError, 'Repository identifier must not be null' if id.nil?

    repository_hash['_id'] = id
    repository_hash.delete_if do |attribute, value|
      not Repository.fields.include?(attribute)
    end
  end
    
end
