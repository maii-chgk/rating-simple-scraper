require "httparty"

require_relative '../importers/tournament_results_importer'
require_relative '../api/tournament_detailed'

class TournamentResultsFetcher
  def initialize(ids:)
    @ids = ids
    @api_client = TournamentResultsAPI.new
    @results = []
  end

  def run
    puts "importing rosters for up to #{@ids.size} tournaments"
    tournaments_data = fetch_tournaments_data
    puts "fetched data for #{tournaments_data.size} tournaments"

    @results = present_results(tournaments_data)

    ids_to_update = @results.reduce(Set.new) { |ids, result| ids << result[:tournament_id] }.to_a
    puts "importing data for #{ids_to_update.size} tournaments"
    TournamentResultsImporter.import(data: @results, ids: ids_to_update)
    puts "data imported"
  end

  def fetch_tournaments_data
    @ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.fetch_results(tournament_id: id)
    end.compact
  end

  def present_results(hash)
    hash.flat_map do |tournament_id, tournament_results|
      tournament_results.flat_map do |team|
        {
          tournament_id: tournament_id,
          team_id: team.dig("team", "id"),
          team_title: team.dig("current", "name"),
          total: team["questionsTotal"],
          position: team["position"],
          old_rating: team.dig("rating", "b"),
          old_rating_delta: team.dig("rating", "d")
        }
      end
    end
  end
end
