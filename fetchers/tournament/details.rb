require "httparty"
require "date"

require_relative '../../importers/tournament_details_importer'
require_relative '../../api/client'

class TournamentDetailsFetcher
  BLOCKLIST = [8521, 8214, 8241]

  def initialize(category:)
    @api_client = APIClient.new
    @category = category
    @tournament_ids = []
    @tournaments_data = []
  end

  def run
    fetch_tournaments_data
    TournamentDetailsImporter.import(data: @tournaments_data, ids: @tournament_ids)
  end

  def fetch_tournaments_data
    page_number = 1
    tournaments = fetch_page(page_number)

    while tournaments.size > 0
      tournaments.each do |tournament|
        next if BLOCKLIST.include?(tournament['id'])

        @tournament_ids << tournament['id']
        @tournaments_data << process_data(tournament)
      end

      puts "fetched page #{page_number}"

      page_number += 1
      tournaments = fetch_page(page_number)
    end
  end

  def fetch_page(page_number)
    case @category
    when :maii
      @api_client.maii_tournaments(page: page_number)
    when :all
      @api_client.all_tournaments(page: page_number)
    when :recent
      @api_client.tournaments_started_after(date: recently, page: page_number)
    when :recently_updated
      @api_client.tournaments_updated_after(date: recently, page: page_number)
    else
      raise ArgumentError, "category should be one of :all, :maii:, :recent, :recently_updated"
    end
  end

  def recently
    (Date.today - 30).to_s
  end

  def process_data(tournament)
    {
      id: tournament['id'],
      title: tournament['name'],
      start_datetime: tournament['dateStart'],
      end_datetime: tournament['dateEnd'],
      last_edited_at: tournament['lastEditDate'],
      questions_count: tournament['questionQty']&.values&.sum,
      type: tournament.dig('type', 'name'),
      typeoft_id: tournament.dig('type', 'id'),
      maii_rating: tournament['maiiRating'],
      maii_rating_updated_at: tournament['maiiRatingUpdatedAt'],
      maii_aegis: tournament['maiiAegis'],
      maii_aegis_updated_at: tournament['maiiAegisUpdatedAt'],
      in_old_rating: tournament['tournamentInRatingBalanced']
    }
  end
end
