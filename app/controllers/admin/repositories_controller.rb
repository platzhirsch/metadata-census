class Admin::RepositoriesController < ApplicationController
  helper_method :repository_count

  def create
    file = params[:file]
    catalog = YAML.load_file(file).with_indifferent_access

    repositories = catalog[:repositories].each do |repository|
      location = Geocoder.search(repository[:location]).first
      repository[:latitude] = location.latitude
      repository[:longitude] = location.longitude

      entity = Repository.find(repository[:id])
      entity = Repository.new if entity.nil?
      entity.update(repository)
    end

    render nothing: true
  end

  def new
    @repository_files = repository_files
  end

  def repository_files
    files = Dir.glob('data/repositories/*.yml').select { |f| File.file?(f) }
    files.map do |yaml| 
      { yaml => YAML.load_file(yaml).with_indifferent_access }
    end.reduce(:merge)
  end

  def repository_count(yaml)
    yaml.except(:name).values.map(&:length).reduce(:+)
  end
    
end
