require_relative "db.rb"
require "httparty"
require 'set'

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
rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
  puts "connection refused, retrying in 3 seconds"
  sleep(3)
  fetch_tournament_rosters(id)
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
  puts "saving #{rosters.size} players"
  columns = [:tournament_id, :team_id, :player_id, :flag, :is_captain]
  DB[:tournament_rosters].import(columns, rosters)
end

def load_batch(from:, to:)
  saved = Set.new(DB[:tournament_rosters].map(:tournament_id))
  (from..to).each do |t_id|
    if saved.include?(t_id)
      puts "#{t_id} already saved"
      next
    end
    rosters = fetch_tournament_rosters(t_id)
    save_rosters(process_tournament(t_id, rosters))
  end
end

load_batch(from: 7212, to: 7212)
