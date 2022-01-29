require_relative "db.rb"
require "httparty"

BATCH_SIZE = 50

def fetch_team(id)
  return nil if id.nil?
  response = HTTParty.get("https://api.rating.chgk.net/teams/#{id}/seasons.json")
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
  puts "saving #{players.size} players"
  columns = [:player_id, :team_id, :season_id, :start_date, :end_date]
  DB[:base_rosters].import(columns, players)
end

def deduplicate
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
  puts "batch size is #{BATCH_SIZE}"
  batch_count = 0

  team_ids.each_slice(BATCH_SIZE) do |batch|
    puts "Processing batch ##{batch_count}/#{team_ids.size / BATCH_SIZE + 1}"
    fetch_and_load_batch(team_ids: batch)
    batch_count += 1
  end
end

def fetch_and_load_batch(team_ids:)
  players = team_ids.flat_map do |t_id|
    rosters = fetch_team(t_id)
    next if rosters.nil?
    rosters.map { |roster| convert_to_array(roster) }
  end
  save_players(players.compact)
  deduplicate
end

def played_maii_tournaments
  DB.fetch("select distinct rr.team_id from rating_tournament t left join rating_result rr on t.id = rr.tournament_id where maii_rating = true limit 150")
    .map(:team_id)
end

def all_teams
  max_team_id = DB.fetch("select max(id) from rating_team").map(:max).first + 500
  (1..max_team_id).to_a
end

def load_maii_rosters
  fetch_and_load_base_rosters(team_ids: played_maii_tournaments)
end

def load_all_rosters
  fetch_and_load_base_rosters(team_ids: all_teams)
end
