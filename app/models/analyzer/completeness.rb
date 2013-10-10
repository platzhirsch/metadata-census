module Analyzer

  class Completeness

    def self.analyze(repository, metric)
      scores = Generic.group_scores_by(repository, metric, %s(record.groups))
      schema_file = File.read('data/schema/ckan.json')

      schema = JSON.parse(schema_file).with_indifferent_access
      properties = fields(schema)

      return { scores: scores, properties: properties }
    end

    def self.treemap(snapshot)
    end

    private
    def self.fields(schema)
      schema[:properties].map do |k, v|
        case v[:type]
        when "array"
          v[:items][:type] == "object" ? [k] + fields(v[:items]) : k
        when "object"
          v[:properties].nil? ? k : fields(v)
        else
          k
        end

      end.compact
    end

  end

end
