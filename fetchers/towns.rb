require "httparty"

require_relative '../importers/towns_importer'
require_relative './full_fetcher'

class TownsFetcher < FullFetcher
  def importer
    TownsImporter
  end

  def api_method
    :towns
  end

  def process_row(town)
    {
      id: town['id'],
      title: town['name']
    }
  end
end
