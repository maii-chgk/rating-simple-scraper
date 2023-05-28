# frozen_string_literal: true

require 'httparty'

require_relative '../importers/base_roster_importer'
require_relative './batch_fetcher'
require_relative '../api/client'

class BaseRostersFetcher < BatchFetcher
  def run_for_batch(team_ids)
    puts "importing rosters for up to #{team_ids.size} teams"
    rosters = fetch_rosters(team_ids)
    puts "fetched data for #{rosters.size} teams"

    delete_empty_rosters(rosters)

    rosters_to_import = present_rosters(rosters)
    ids_to_update = rosters_to_import.reduce(Set.new) { |ids, roster| ids << roster[:team_id] }.to_a
    puts "importing data for #{ids_to_update.size} teams"
    BaseRostersImporter.import(data: rosters_to_import, ids: ids_to_update)
    puts 'data imported'
  end

  def delete_empty_rosters(rosters)
    rosters_to_delete = rosters.select { |_team_id, team_rosters| team_rosters.empty? }.keys
    puts "will delete rosters for these teams: #{rosters_to_delete}"
    BaseRostersImporter.delete_rosters_for(team_ids: rosters_to_delete)
  end

  def fetch_rosters(ids)
    ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.team_rosters(team_id: id)
      if (hash.size % 10).zero?
        puts "fetched roster for team ##{hash.size}"
        sleep 3
      end
    end
  end

  def present_rosters(hash)
    hash.flat_map do |team_id, players|
      if players.is_a? String
        puts "Malformed data for team #{team_id}, skipping it"
        next
      end
      players.flat_map do |player|
        {
          team_id: player['idteam'],
          player_id: player['idplayer'],
          season_id: player['idseason'],
          start_date: player['dateAdded'],
          end_date: player['dateRemoved']
        }
      end
    end.compact
  end
end
