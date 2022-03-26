require "httparty"

require_relative '../../importers/tournament_rosters_importer'
require_relative '../batch_fetcher'
require_relative '../../api/legacy_client'

class TournamentRostersFetcher < BatchFetcher
  def initialize(ids:)
    super
    @results = []
    @api_client = LegacyAPIClient.new
  end

  def run_for_batch(tournament_ids)
    puts "importing rosters for up to #{tournament_ids.size} tournaments"
    tournaments_data = fetch_tournaments_data(tournament_ids)
    puts "fetched data for #{tournaments_data.size} tournaments"

    @rosters = present_rosters(tournaments_data)

    ids_to_update = @rosters.reduce(Set.new) { |ids, roster| ids << roster[:tournament_id] }.to_a
    puts "importing data for #{ids_to_update.size} tournaments"
    TournamentRostersImporter.import(data: @rosters, ids: ids_to_update)
    puts "data imported"
  end

  def fetch_tournaments_data(ids)
    ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.fetch_rosters(tournament_id: id)
    end.compact
  end

  def present_rosters(hash)
    hash.flat_map do |tournament_id, tournament_teams|
      tournament_teams.flat_map do |team|
        roster = present_team_roster(team)
        if roster&.size > 0
          roster.map { |player| player.update(tournament_id: tournament_id) }
        else
          nil
        end
      end
    end.compact
  end

  def present_team_roster(team)
    team_id = team.dig("idteam")
    team.fetch("recaps", []).map do |player|
      flag = if player["is_base"] == "1"
               "Б"
             elsif player["is_foreign"] == "0"
               "Л"
             else
               nil
             end
      {
        team_id: team_id,
        player_id: player["idplayer"],
        flag: flag,
        is_captain: player["is_captain"] == "1"
      }
    end
  end
end
