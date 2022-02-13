require_relative "../fetchers/base_rosters"

def played_maii_tournaments
  DB.fetch("select distinct r.team_id from tournaments t left join tournament_results r on t.id = r.tournament_id where maii_rating = true and r.team_id is not null")
    .map(:team_id)
end

BaseRostersFetcher.new(ids: played_maii_tournaments).run


def load_all_rosters(first_id:, last_id: nil)
  last_id ||= DB.fetch("select max(id) from rating_team").map(:max).first + 500
  fetch_and_load_base_rosters(team_ids: (first_id..last_id).to_a)
end
