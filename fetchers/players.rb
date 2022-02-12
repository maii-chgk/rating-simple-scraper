require "httparty"

require_relative '../importers/players_importer'
require_relative '../api/client'

class PlayersFetcher
  def initialize
    @api_client = APIClient.new
    @player_ids = []
    @players_data = []
  end

  def run
    fetch_players_data
    PlayersImporter.import(data: @players_data, ids: @player_ids)
  end

  def fetch_players_data
    page_number = 1
    players = fetch_page(page_number)

    while players.size > 0
      players.each do |player|
        @player_ids << player['id']
        @players_data << {
          id: player['id'],
          first_name: player['name'],
          patronymic: player['patronymic'],
          last_name: player['surname']
        }
      end

      puts "fetched page #{page_number}"

      page_number += 1
      players = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.players(page: page)
  end
end
