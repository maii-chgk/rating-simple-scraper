require_relative 'db'
require_relative './fetchers/towns'
require_relative './fetchers/teams'
require_relative './fetchers/players'
require_relative './fetchers/base_rosters'

namespace :towns do
  task :fetch_all do
    fetch_all_towns
  end
end

namespace :teams do
  task :fetch_all do
    fetch_all_teams
  end
end

namespace :players do
  task :fetch_all do
    fetch_all_players
  end
end

namespace :base_rosters do
  task :fetch_id_range, [:first_id, :last_id] do |t, args|
    last_id = args[:last_id] || max_team_id + 500
    ids = (args[:first_id].to_i..last_id.to_i).to_a
    BaseRostersFetcher.new(ids: ids).run
  end

  task :fetch_for_teams_in_rating_tournaments do
    BaseRostersFetcher.new(ids: teams_that_played_rating_tournaments).run
  end
end

namespace :tournaments do

end