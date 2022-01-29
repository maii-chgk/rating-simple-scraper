require_relative "db.rb"
require "httparty"

def recent_tournaments
  query = <<~SQL
    with teams_count as (
        select tournament_id, count(distinct team_id) as teams
        from rating_result
        group by tournament_id
    ),
    editors_count as (
        select tournament_id, count(distinct player_id) as editors
        from editors
        group by tournament_id
    )

    select t.id, t.title, tc.teams, e.editors
    from public.rating_tournament t
    left join teams_count tc on t.id = tc.tournament_id
    left join editors_count e on t.id = e.tournament_id
    where end_datetime >= '2016-01-01'
        and title not ilike 'онлайн%'
        and title not ilike '%общий зачёт%'
        and tc.teams >= 5
        and e.editors is null
  SQL

  DB.fetch(query).map(:id)
end

def fetch_tournament_details(tournament_id)
  puts "fetching data for #{tournament_id}"
  response = HTTParty.get("https://api.rating.chgk.net/tournaments/#{tournament_id}.json")
  if response.code == 200
    response.parsed_response
  else
    puts response.body
    nil
  end
rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
  puts "connection refused, retrying in 3 seconds"
  sleep(3)
  retry
end

def load_editors(tournament_id)
  response = fetch_tournament_details(tournament_id)
  response["editors"].map { |editor_hash| [tournament_id, editor_hash["id"], [editor_hash["name"], editor_hash["surname"]].join(" ")] }
end

def create_table
  DB.create_table? :editors do
    primary_key :id
    column :tournament_id, Integer
    column :player_id, Integer
    column :name, String
  end
end

def save_editors(editors)
  columns = [:tournament_id, :player_id, :name]
  DB[:editors].import(columns, editors)
end

def run
  puts DateTime.now
  puts "Creating table"
  create_table

  puts DateTime.now
  puts "loading list of tournaments"
  ids = recent_tournaments

  puts DateTime.now
  puts "loading details for #{ids.size} more tournaments"
  editors = ids.flat_map { |id| load_editors(id) }
  puts DateTime.now
  puts "saving editors"
  save_editors(editors)
  puts "saved editors"

  until ids.empty?
    puts DateTime.now
    puts "loading details for #{ids.size} more tournaments"
    editors = ids.flat_map { |id| load_editors(id) }
    puts DateTime.now
    puts "saving editors"
    save_editors(editors)
    puts "saved editors"

    ids = recent_tournaments
  end

  puts DateTime.now
end

run
