require 'sequel'

connection_string = ENV.fetch('CONNECTION_STRING', 'postgres://localhost/postgres')
DB = Sequel.connect(connection_string)

def max_team_id
  DB.fetch("select max(id) from teams").map(:max).first
end

def teams_that_played_rating_tournaments
  DB.fetch("select distinct r.team_id from tournaments t left join tournament_results r on t.id = r.tournament_id where maii_rating = true and r.team_id is not null")
    .map(:team_id)
end