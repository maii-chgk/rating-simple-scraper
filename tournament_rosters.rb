require_relative "db.rb"
require "httparty"
require "honeybadger"

MAIN_ROSTERS_TABLE = :tournament_rosters
TEMP_ROSTERS_TABLE = :tournament_rosters_temp

def create_temp_table
  DB.create_table? TEMP_ROSTERS_TABLE do
    primary_key :id
    column :tournament_id, Integer
    column :team_id, Integer
    column :player_id, Integer
    column :flag, String
    column :is_captain, TrueClass
  end
end

def fetch_tournament_rosters(id)
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

def process_tournament(tournament_id, rosters)
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

def save_rosters(rosters)
  columns = [:tournament_id, :team_id, :player_id, :flag, :is_captain]
  DB[TEMP_ROSTERS_TABLE].import(columns, rosters)
end

def update_main_table(tournament_ids:)
  DB.transaction do
    DB.run("delete from #{MAIN_ROSTERS_TABLE} where tournament_id in (#{tournament_ids.join(',')})")
    DB.run("insert into #{MAIN_ROSTERS_TABLE} (select * from #{TEMP_ROSTERS_TABLE})")
    DB.drop_table(TEMP_ROSTERS_TABLE)
  end
end

def maii_tournaments
  DB.fetch("select id from rating_tournament where maii_rating = true and end_datetime <= now() + interval '1 week'")
    .map(:id)
end

def fetch_and_save_tournament_rosters(tournament_ids:)
  create_temp_table
  puts DateTime.now
  puts "Fetching and saving rosters for #{tournament_ids.size} tournaments"
  tournament_ids.each do |t_id|
    rosters = fetch_tournament_rosters(t_id)
    puts "Saving #{rosters&.size} rosters for #{t_id}"
    save_rosters(process_tournament(t_id, rosters))
  end
  puts DateTime.now
  puts "Updating main roster table with updated rosters"
  update_main_table(tournament_ids: tournament_ids)
  puts "Update completed"
  puts DateTime.now
rescue => e
  Honeybadger.notify(e)
  raise e
end

fetch_and_save_tournament_rosters(tournament_ids: maii_tournaments)
