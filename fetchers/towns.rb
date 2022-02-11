require "httparty"

require_relative '../importers/towns_importer'
require_relative '../api/client'

class TownsFetcher
  def initialize
    @api_client = APIClient.new
    @town_ids = []
    @towns_data = []
  end

  def run
    fetch_towns_data
    TownsImporter.import(data: @towns_data, ids: @town_ids)
  end

  def fetch_towns_data
    page_number = 1
    towns = fetch_page(page_number)

    while towns.size > 0
      towns.each do |town|
        @town_ids << town['id']
        @towns_data << {
          id: town['id'],
          title: town['name']
        }
      end

      puts "fetched page #{page_number}"

      page_number += 1
      towns = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.towns(page: page)
  end
end
