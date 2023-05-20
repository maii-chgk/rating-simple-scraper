# frozen_string_literal: true

require 'httparty'

require_relative '../importers/base_roster_importer'
require_relative './batch_fetcher'
require_relative '../api/client'

class BaseRostersFetcher < BatchFetcher
  def run_for_batch(team_ids)
    puts "importing rosters for up to #{team_ids.size} teams"
    rosters_raw = fetch_rosters(team_ids)
    puts "fetched data for #{rosters_raw.size} teams"

    rosters_to_delete = rosters_raw.select { |_team_id, team_rosters| team_rosters.empty? }.keys
    delete_empty_rosters(rosters_to_delete) unless rosters_to_delete.empty?

    rosters = present_rosters(rosters_raw)
    ids_to_update = rosters.reduce(Set.new) { |ids, roster| ids << roster[:team_id] }.to_a
    puts "importing data for #{ids_to_update.size} teams"
    BaseRostersImporter.import(data: rosters, ids: ids_to_update)
    puts 'data imported'
  end

  def fetch_rosters(ids)
    ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.team_rosters(team_id: id)
      puts "fetched roster for team #{hash.size}" if (hash.size % 10).zero?
    end
  end

  def present_rosters(hash)
    hash.flat_map do |_, players|
      players.flat_map do |player|
        {
          team_id: player['idteam'],
          player_id: player['idplayer'],
          season_id: player['idseason'],
          start_date: player['dateAdded'],
          end_date: player['dateRemoved']
        }
      end
    end
  end

  def delete_empty_rosters(team_ids)
    puts "will delete rosters for these teams: #{team_ids}"
    BaseRostersImporter.delete_rosters_for(team_ids:)
  end
end
