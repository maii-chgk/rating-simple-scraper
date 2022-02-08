require "httparty"

require_relative "../db.rb"
require_relative '../strategies/temp_table'

class TournamentRostersFetcher < TempTableStrategy
  def main_table_name
    "tournament_rosters"
  end

  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      column :id, "bigserial"
      Integer :tournament_id
      Integer :team_id
      Integer :player_id
      String :flag
      TrueClass :is_captain
    end
  end

  def columns_to_import
    [:tournament_id, :team_id, :player_id, :flag, :is_captain]
  end

  def id_name
    "tournament_id"
  end

  def fetch_data(id)
    puts "fetching #{id}"
    response = HTTParty.get("https://rating.chgk.info/api/tournaments/#{id}/recaps.json")
    if response.code == 200
      response.parsed_response
    elsif response.code == 404
      puts "#{id} missing"
      nil
    else
      puts response.body
      nil
    end
  rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
    puts "connection refused, retrying in 3 seconds"
    sleep(3)
    retry
  end

  def process_data(tournament_id, rosters)
    return [] if rosters.nil?
    rosters.flat_map { |roster| process_roster(tournament_id, roster) }
  end

  def process_roster(tournament_id, roster)
    team_id = roster["idteam"].to_i
    roster["recaps"].map do |player|
      flag = if player["is_base"] == "1"
               "Б"
             elsif player["is_foreign"] == "0"
               "Л"
             else
               nil
             end
      is_captain = player["is_captain"] == "1"
      [tournament_id, team_id, player["idplayer"].to_i, flag, is_captain]
    end
  end
end

def maii_tournaments
  DB.fetch("select id from rating_tournament where maii_rating = true and end_datetime <= now() + interval '1 week'")
    .map(:id)
end
