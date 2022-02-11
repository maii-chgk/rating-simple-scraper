require "httparty"

require_relative '../importers/teams_importer'
require_relative '../api/client'

class TeamsFetcher
  def initialize
    @api_client = APIClient.new
    @teams_ids = []
    @teams_data = []
  end

  def run
    fetch_teams_data
    TeamsImporter.import(data: @teams_data, ids: @teams_ids)
  end

  def fetch_teams_data
    page_number = 1
    teams = fetch_page(page_number)

    while teams.size > 0
      teams.each do |team|
        @teams_ids << team['id']
        @teams_data << {
          id: team['id'],
          title: team['name']
        }
      end

      puts "fetched page #{page_number}"

      page_number += 1
      teams = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.teams(page: page)
  end
end
