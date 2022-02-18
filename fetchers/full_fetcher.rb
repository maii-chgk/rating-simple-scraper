require "httparty"

require_relative '../importers/teams_importer'
require_relative '../api/client'

class FullFetcher
  # Goes through all available pages for a resource

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
      puts "fetched page #{page_number}"

      ids = entries.map { |entry| entry["id"]}
      data = entries.map { |entry| process_row(entry) }
      importer.import(data: data, ids: ids)
      puts "imported #{ids.size} rows"

      page_number += 1
      entries = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.send(api_method, page: page)
  end
end
