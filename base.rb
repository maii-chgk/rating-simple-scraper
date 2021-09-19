require_relative "db.rb"
require "httparty"
require 'set'

def fetch_team(id)
  return nil if id.nil?
  puts "fetching #{id}"
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

def load_batch(team_ids:)
  saved = Set.new(DB[:base_rosters].map(:team_id))
  puts "#{saved.size} already saved"
  puts DateTime.now
  players = team_ids.flat_map do |t_id|
    if saved.include?(t_id)
      next
    end
    rosters = fetch_team(t_id)
    # next if rosters.nil? || rosters.size == 0
    next if rosters.nil?
    rosters.map { |roster| conver t_to_array(roster) }
  end
  save_players(players.compact)
end

def release_top_teams(n: 100)
  DB.fetch("select team_id from b.releases where release_details_id = 9 order by rating desc limit #{n}")
    .map(:team_id)
end

def played_maii_tournaments
  DB.fetch("select rr.team_id from rating_tournament t left join rating_result rr on t.id = rr.tournament_id where maii_rating = true")
    .map(:team_id)
end

puts DateTime.now
load_batch(team_ids: played_maii_tournaments)
puts DateTime.now



