require '../../db'

def maii_tournaments
  DB.fetch("select id from rating_tournament where maii_rating = true and end_datetime <= now() + interval '1 week'")
    .map(:id)
end
