require_relative "db.rb"
require "httparty"
require 'set'

def fetch_tournament(id)
  puts "fetching #{id}"
  response = HTTParty.get("https://rating.chgk.info/api/tournaments/#{id}.json")
  if response.code == 200
    response.parsed_response.first
  elsif response.code == 404
    puts "#{id} missing"
    nil
  else
    puts response.body
    nil
  end
end

def truncate
  DB[:tournaments].truncate
end

def convert_to_array(t_hash)
  return nil if t_hash.nil?
  end_date = if t_hash["date_end"] == "0000-00-00 00:00:00"
               nil
             else
               t_hash["date_end"]
             end
  [
    t_hash['idtournament'].to_i,
    t_hash['name'],
    t_hash['long_name'],
    t_hash['date_start'],
    end_date,
    t_hash['questions_total'].to_i,
    t_hash['tournament_in_rating'] == "1" ? true : false
  ]
end

def save_tournaments(tournaments)
  puts "saving #{tournaments.size} tournaments"
  columns = [:id, :name, :long_name, :start_date, :end_date, :questions, :in_old_rating]
  DB[:tournaments].import(columns, tournaments)
end

def load_batch(from:, to:)
  saved = Set.new(DB[:tournaments].map(:id))
  tournaments = []
  (from..to).each do |t_id|
    if saved.include?(t_id)
      puts "#{t_id} already saved"
      next
    end
    hash = fetch_tournament(t_id)
    tournaments << convert_to_array(hash)
  end
  tournaments.compact!
  save_tournaments(tournaments)
end

load_batch(from: 7000, to: 7438)
