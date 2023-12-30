# frozen_string_literal: true

require 'httparty'

require_relative '../importers/teams_importer'
require_relative '../api/client'
require_relative '../logging'

class FullFetcher
  # Goes through all available pages for a resource

  include Loggable

  BATCH_SIZE = 100

  def initialize
    @api_client = APIClient.new
    @ids = []
    @data = []
  end

  def importer
    raise NotImplementedError
  end

  def api_method
    raise NotImplementedError
  end

  def process_row(row)
    raise NotImplementedError
  end

  def run
    page_number = 1
    entries = fetch_page(page_number)

    while entries.size > 0
      logger.info "fetched page #{page_number}"

      ids = entries.map { |entry| entry['id'] }
      data = entries.map { |entry| process_row(entry) }
      importer.import(data:, ids:)
      logger.info "imported #{ids.size} rows"

      page_number += 1
      entries = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.send(api_method, page:)
  end
end
