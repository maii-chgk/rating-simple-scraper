# frozen_string_literal: true

require 'httparty'

require_relative '../../importers/tournament_rosters_importer'
require_relative '../batch_fetcher'
require_relative '../../api/client'

class TournamentRostersFetcher < BatchFetcher
  def initialize(ids:)
    super
    @results = []
    @api_client = APIClient.new
  end

  def run_for_batch(tournament_ids)
    puts "importing rosters for up to #{tournament_ids.size} tournaments"
    tournaments_data = fetch_tournaments_data(tournament_ids)
    puts "fetched data for #{tournaments_data.size} tournaments"

    @rosters = present_rosters(tournaments_data)

    ids_to_update = @rosters.reduce(Set.new) { |ids, roster| ids << roster[:tournament_id] }.to_a
    puts "importing data for #{ids_to_update.size} tournaments"
    TournamentRostersImporter.import(data: @rosters, ids: ids_to_update)
    puts 'data imported'
  end

  def fetch_tournaments_data(ids)
    ids.each_with_object({}) do |id, hash|
      response = @api_client.tournament_rosters(tournament_id: id)
      hash[id] = response if response.is_a?(Array)
    end.compact
  end

  def present_rosters(hash)
    hash.flat_map do |tournament_id, tournament_teams|
      tournament_teams.flat_map do |team|
        roster = present_team_roster(team)
        roster.map { |player| player.update(tournament_id:) } if roster&.size&.> 0
      end
    end.compact
  end

  def present_team_roster(team)
    team_id = team.dig('team', 'id')
    team.fetch('teamMembers', []).map do |player|
      {
        team_id:,
        player_id: player.dig('player', 'id'),
        flag: player['flag'],
        is_captain: nil
      }
    end
  end
end
