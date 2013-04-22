class MetricsController < ApplicationController
  def overview
  end

  def completeness
    documents = Tire.search 'ckan' do
      query { all }
    end.results

    schema = JSON.parse File.read 'public/ckan-schema.json'
    scores = []

    for entry in documents
      metric = Metrics::Completeness.new
      document = JSON.parse entry.to_json
      metric.compute document, schema
      scores << metric.score
    end

    redirect_to :action => 'overview', :score => scores.inject(:+) / scores.length
  end
end
