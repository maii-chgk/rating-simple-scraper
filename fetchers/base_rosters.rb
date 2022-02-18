require "httparty"

require_relative '../importers/base_roster_importer'
require_relative '../api/client'

BATCH_SIZE = 50

class BaseRostersFetcher
  def initialize(ids:)
    @ids = ids
    @api_client = APIClient.new
  end

  def run
    puts "importing rosters for up to #{@ids.size} teams"

    puts "batch size is #{BATCH_SIZE}"
    batches_count = (Float(@ids.size) / BATCH_SIZE).ceil
    current_batch = 1

    @ids.each_slice(BATCH_SIZE) do |batch|
      puts "Processing batch ##{current_batch}/#{batches_count}"
      run_for_batch(team_ids: batch)
      current_batch += 1
    end
  end

  def run_for_batch(team_ids:)
    puts "importing rosters for up to #{team_ids.size} teams"
    rosters_raw = fetch_rosters(team_ids)
    puts "fetched data for #{rosters_raw.size} teams"

    rosters = present_rosters(rosters_raw)

    ids_to_update = rosters.reduce(Set.new) { |ids, roster| ids << roster[:team_id] }.to_a
    puts "importing data for #{ids_to_update.size} teams"
    BaseRostersImporter.import(data: rosters, ids: ids_to_update)
    puts "data imported"
  end

  def fetch_rosters(ids)
    ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.team_rosters(team_id: id)
      puts "fetched roster for team #{hash.size}" if hash.size % 10 == 0
    end.compact
  end

  def present_rosters(hash)
    hash.flat_map do |_, players|
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
