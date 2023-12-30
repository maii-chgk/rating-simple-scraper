# frozen_string_literal: true

require 'httparty'

require_relative '../importers/teams_importer'
require_relative 'full_fetcher'

class TeamsFetcher < FullFetcher
  def importer
    TeamsImporter
  end

  def api_method
    :teams
  end

  def process_row(team)
    {
      id: team['id'],
      title: team['name'],
      town_id: team.dig('town', 'id')
    }
  end
end

def fetch_all_teams
  TeamsFetcher.new.run
end
