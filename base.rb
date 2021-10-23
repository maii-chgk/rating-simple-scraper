require_relative "db.rb"
require "httparty"

def fetch_team(id)
  return nil if id.nil?
  response = HTTParty.get("https://api.rating.chgk.net/team_seasons.json?idteam=#{id}")
  if response.code == 200
    response.parsed_response
  elsif response.code == 404
    puts "#{id} missing"
    nil
  else
    puts response.body
    nil
  end
end

def convert_to_array(hash)
  return nil if hash.nil?
  [
    hash['idplayer'],
    hash['idteam'],
    hash['idseason'],
    hash['dateAdded'],
    hash['dateRemoved']
  ]
end

def save_players(players)
  puts DateTime.now
  puts "saving #{players.size} players"
  columns = [:player_id, :team_id, :season_id, :start_date, :end_date]
  DB[:base_rosters].import(columns, players)
end

def deduplicate
  puts DateTime.now
  puts "Starting deduplication"

  query = <<~QUERY
    with grouped as (
      select id, 
          row_number() over (partition by player_id, team_id, season_id order by id) as row_number
      from base_rosters
    )
    delete from base_rosters
    where id in (select id from grouped where row_number > 1);
  QUERY
  DB.run(query)
  puts "Deduplication completed"
end

def fetch_and_load_base_rosters(team_ids:)
  puts "loading data for #{team_ids.size} teams"
  puts DateTime.now
  count = 0
  players = team_ids.flat_map do |t_id|
    count += 1
    if count % 10 == 0
      puts "team ##{count}"
    end
    rosters = fetch_team(t_id)
    next if rosters.nil?
    rosters.map { |roster| convert_to_array(roster) }
  end
  save_players(players.compact)
  deduplicate
end


def played_maii_tournaments
  DB.fetch("select rr.team_id from rating_tournament t left join rating_result rr on t.id = rr.tournament_id where maii_rating = true")
    .map(:team_id)
end

puts DateTime.now
fetch_and_load_base_rosters(team_ids: played_maii_tournaments)
puts DateTime.now
