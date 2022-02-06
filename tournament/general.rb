require "httparty"

require_relative "../db.rb"
require_relative '../strategies/temp_table'
require_relative '../api/tournaments'

class TournamentDetailsFetcher < TempTableStrategy
  def initialize(ids:)
    @api_client = TournamentsAPI.new
    super
  end

  def main_table_name
    "tournaments"
  end

  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      Integer :id
      String :title
      DateTime :start_datetime
      DateTime :end_datetime
      DateTime :updated_at
      Integer :questions_count
      Integer :typeoft_id
      String :type
      TrueClass :maii_rating
      DateTime :maii_rating_updated_at
      TrueClass :maii_aegis
      DateTime :maii_aegis_updated_at
    end
  end

  def columns_to_import
    [:id, :title,
     :start_datetime, :end_datetime, :updated_at,
     :questions_count, :typeoft_id, :type,
     :maii_rating, :maii_rating_updated_at,
     :maii_aegis, :maii_aegis_updated_at]
  end

  def id_name
    "id"
  end

  def run
    list_tournaments
    super
  end

  def list_tournaments
    page_number = 1
    @tournaments_data = {}
    tournaments = @api_client.maii_tournaments(page: page_number)
    while tournaments.size > 0
      tournaments.each do |tournament|
        @tournaments_data[tournament['id']] = tournament
      end
      page_number += 1
      tournaments = @api_client.maii_tournaments(page: page_number)
    end
  end

  def fetch_data(id)
    @tournaments_data.fetch(id)
  end

  def process_data(id, tournament)
    [tournament['id'], tournament['name'],
     tournament['dateStart'], tournament['dateEnd'], tournament['lastEditDate'],
     questions_count(tournament['questionQty']),
     tournament, :type,
     :maii_rating, :maii_rating_updated_at,
     :maii_aegis, :maii_aegis_updated_at]
  end

  def questions_count(questions_hash)
    questions_hash.values.sum
  end
end
