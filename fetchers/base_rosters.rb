require "httparty"

require_relative '../importers/base_roster_importer'
require_relative '../api/client'

class BaseRostersFetcher
  def initialize(ids:)
    @ids = ids
    @api_client = APIClient.new
  end

  def run
    puts "importing rosters for up to #{@ids.size} teams"
    rosters_raw = fetch_rosters
    puts "fetched data for #{rosters_raw.size} teams"

    rosters = present_rosters(rosters_raw)

    ids_to_update = rosters.reduce(Set.new) { |ids, roster| ids << roster[:team_id] }.to_a
    puts "importing data for #{ids_to_update.size} tournaments"
    BaseRostersImporter.import(data: rosters, ids: ids_to_update)
    puts "data imported"
  end

  def fetch_rosters
    @ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.team_rosters(team_id: id)
      puts "fetched roster for team #{hash.size}" if hash.size % 10 == 0
    end.compact
  end

  def present_rosters(hash)
    hash.flat_map do |team_id, players|
      players.flat_map do |player|
        {
          team_id: player["idteam"],
          player_id: player["idplayer"],
          season_id: player["idseason"],
          start_date: player["dateAdded"],
          end_date: player["dateRemoved"]
        }
      end
    end
  end
end
