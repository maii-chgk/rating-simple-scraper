# frozen_string_literal: true

require 'httparty'
require_relative '../logger'

class BatchFetcher
  BATCH_SIZE = 50
  include Loggable

  def initialize(batch_size = BATCH_SIZE, ids:)
    @batch_size = batch_size
    @ids = ids
    @api_client = APIClient.new
  end

  def run
    logger.info "importing data for up to #{@ids.size} ids"
    logger.info "batch size is #{@batch_size}"
    batches_count = (Float(@ids.size) / @batch_size).ceil
    current_batch = 1

    @ids.each_slice(BATCH_SIZE) do |batch|
      logger.info "Processing batch ##{current_batch}/#{batches_count}"
      run_for_batch(batch)
      current_batch += 1
    end
  end

  def run_for_batch(ids)
    raise NotImplementedError
  end
end
