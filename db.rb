require 'sequel'

connection_string = ENV.fetch('CONNECTION_STRING', 'postgres://localhost/postgres')
ENV['PGOPTIONS'] = '-c statement_timeout=60s'
DB = Sequel.connect(connection_string)

def max_team_id
  DB.fetch("select max(id) from teams").map(:max).first
end

def teams_that_played_rating_tournaments
  DB.fetch("select distinct r.team_id from tournaments t left join tournament_results r on t.id = r.tournament_id where maii_rating = true and r.team_id is not null")
    .map(:team_id)
end

def rating_tournaments
  DB.fetch("select id from tournaments where maii_rating = true and end_datetime <= now() + interval '1 week'")
    .map(:id)
end

def all_tournaments
  DB.fetch("select id from tournaments")
    .map(:id)
end

def recent_tournaments(days:)
  DB.fetch("select id from tournaments where end_datetime < now() and end_datetime > now() - interval '? days'", days)
    .map(:id)
end
