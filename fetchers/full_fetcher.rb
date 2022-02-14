require "httparty"

require_relative '../importers/teams_importer'
require_relative '../api/client'

class FullFetcher
  # Goes through all available pages for a resource

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
    fetch_data
    puts "importing #{@ids.size} entries"
    importer.import(data: @data, ids: @ids)
  end

  def fetch_data
    page_number = 1
    entries = fetch_page(page_number)

    while entries.size > 0
      entries.each do |entry|
        @ids << entry["id"]
        @data << process_row(entry)
      end

      puts "fetched page #{page_number}"

      page_number += 1
      entries = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.send(api_method, page: page)
  end
end
