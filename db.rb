# frozen_string_literal: true

require 'sequel'

POSTGRES_CONNECTION_STRING = ENV.fetch('CONNECTION_STRING', 'postgres://postgres:password@localhost:5432/postgres')
ENV['PGOPTIONS'] = '-c statement_timeout=60s'
DB = Sequel.connect(POSTGRES_CONNECTION_STRING) unless ENV['RUBY_ENV'] == 'test'

def max_team_id
  DB.fetch('select max(id) from teams').map(:max).first
end

def teams_that_played_rating_tournaments
  query = 'select distinct r.team_id
           from tournaments t
           left join tournament_results r
             on t.id = r.tournament_id
           where maii_rating = true and r.team_id is not null'

  DB.fetch(query)
    .map(:team_id)
end

def rating_tournaments
  DB.fetch("select id from tournaments where maii_rating = true and end_datetime <= now() + interval '1 week'")
    .map(:id)
end

def all_tournaments
  DB.fetch('select id from tournaments')
    .map(:id)
end

def recent_tournaments(days:)
  DB.fetch("select id from tournaments where end_datetime < now() and end_datetime > now() - interval '? days'", days)
    .map(:id)
end

def tournaments_after(date)
  DB[:tournaments]
    .where(maii_rating: true)
    .where { start_datetime > date }
    .where { end_datetime < Time.now }
end

def vacuum_full
  # We need another connection, with a larger statement timeout
  ENV['PGOPTIONS'] = '-c statement_timeout=3600s'
  connection_string = POSTGRES_CONNECTION_STRING
  connection = Sequel.connect(connection_string)
  connection.run('vacuum full')
end

def fetch_base_teams(players:, date:)
  query = <<~SQL
    select team_id from base_rosters
    where season_id = (select id from seasons where start < ? and "end" > ?)
       and start_date < ? and (end_date is null or end_date > ?)
       and player_id in ?
  SQL
  DB.fetch(query, date, date, date, date, players)
    .map(:team_id)
end

def fetch_tournament_rosters(tournament_id)
  DB[:tournament_rosters].where(tournament_id:)
end
