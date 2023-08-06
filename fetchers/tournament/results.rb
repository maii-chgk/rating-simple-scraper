# frozen_string_literal: true

require 'httparty'

require_relative '../../importers/tournament_results_importer'
require_relative '../batch_fetcher'
require_relative '../../api/client'

class TournamentResultsFetcher < BatchFetcher
  def initialize(ids:)
    super
    @results = []
  end

  def run_for_batch(tournament_ids)
    logger.info "importing results for up to #{tournament_ids.size} tournaments"
    tournaments_data = fetch_tournaments_data(tournament_ids)
    logger.info "fetched data for #{tournaments_data.size} tournaments"

    @results = present_results(tournaments_data)

    ids_to_update = @results.reduce(Set.new) { |ids, result| ids << result[:tournament_id] }.to_a
    logger.info "importing data for #{ids_to_update.size} tournaments"
    TournamentResultsImporter.import(data: @results, ids: ids_to_update)
    logger.info 'data imported'
  end

  def fetch_tournaments_data(ids)
    ids.each_with_object({}) do |id, hash|
      hash[id] = @api_client.tournament_results(tournament_id: id)
      logger.info "fetched tournament #{hash.size}" if hash.size % 10 == 0
    end.compact
  end

  def present_results(hash)
    hash.flat_map do |tournament_id, tournament_results|
      next if tournament_results.is_a?(String)

      tournament_results.flat_map do |team|
        {
          tournament_id:,
          team_id: team.dig('team', 'id'),
          team_title: team.dig('current', 'name'),
          team_city_id: team.dig('current', 'town', 'id'),
          total: team['questionsTotal'],
          position: team['position'],
          old_rating: team.dig('rating', 'b'),
          old_rating_delta: team.dig('rating', 'd')
        }
      end
    end.compact
  end
end
