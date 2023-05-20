# frozen_string_literal: true

require 'httparty'

require_relative '../importers/players_importer'
require_relative './full_fetcher'

class PlayersFetcher < FullFetcher
  def importer
    PlayersImporter
  end

  def api_method
    :players
  end

  def process_row(player)
    {
      id: player['id'],
      first_name: player['name'],
      patronymic: player['patronymic'],
      last_name: player['surname']
    }
  end
end

def fetch_all_players
  PlayersFetcher.new.run
end
