require '../../db'

def maii_tournaments
  DB.fetch("select id from tournament_details where maii_rating = true and end_datetime <= now() + interval '1 week'")
    .map(:id)
end

def all_tournaments
  DB.fetch("select id from tournament_details")
    .map(:id)
end

def recent_tournaments
  DB.fetch("select id from tournament_details where end_datetime > now() - interval '3 months'")
    .map(:id)
end
