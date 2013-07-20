require 'typhoeus'

module Metrics

  class LinkChecker < Metric
    attr_reader :score

    def initialize(metadata, worker=nil)
      @worker = worker
      @processed = 0
      @requests = 0
      @total = metadata.length
      @dispatcher = Typhoeus::Hydra.hydra

      @resource_availability = Hash.new { |h, k| h[k] = Hash.new }
      metadata.each_with_index do |dataset, i|
        dataset[:resources].each do |resource|
          @total += 1
          url = resource[:url]
          id = dataset[:id]
          enqueue_request(id, url)
        end
        @worker.at(i + i, @total)
      end
    end

    def compute(record)
      @score = 0.0
      # blocking call
      @dispatcher.run
      id = record[:id]
      values = @resource_availability[id].values
      @score = values.select { |b| b }.size / values.size.to_f
      @score = 0.0 unless @score.finite?
    end

    def enqueue_request(id, url)

      config = {:method => :head,
                :timeout => 20,
                :connecttimeout => 10,
                :nosignal => true}

      @resource_availability[id][url] = false
      request = Typhoeus::Request.new(url, config)
      request.on_complete do |response|
        if response.success?
          @resource_availability[id][url] = true
        end
        @worker.at(@processed + 1, @requests)
        @processed += 1
      end
      @dispatcher.queue(request)
      @requests += 1
    end

  end

end