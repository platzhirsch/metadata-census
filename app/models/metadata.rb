require 'digest'

class Metadata
  include Mongoid::Document

  validates_presence_of :record, :repository, :date, :type

  field :record
  field :repository
  field :date
  field :type

  ##
  # Custom default identifier which comprisees of the harvesting date, the
  # repository identifier and the metadata record identifier.
  #
  field :_id, default: -> do
    unique = [date, repository.id, record[:id]].join("-")
    Digest::MD5.hexdigest(unique)
  end

  belongs_to :repository

end