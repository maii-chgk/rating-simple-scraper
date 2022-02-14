require_relative 'db'
require_relative './fetchers/towns'
require_relative './fetchers/teams'
require_relative './fetchers/players'
require_relative './fetchers/base_rosters'
require_relative './fetchers/tournament/details'
require_relative './fetchers/tournament/results'
require_relative './fetchers/tournament/rosters'
require_relative './standalone/season'

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
  task :details_for_all_tournaments do
    TournamentDetailsFetcher.new(category: :all).run
  end

  task :details_for_rating_tournaments do
    TournamentDetailsFetcher.new(category: :maii).run
  end

  task :details_for_recent_tournaments do
    TournamentDetailsFetcher.new(category: :recent).run
  end

  task :details_for_recently_updated_tournaments do
    TournamentDetailsFetcher.new(category: :recently_updated).run
  end

  task :results_for_all do
    TournamentResultsFetcher.new(ids: all_tournaments).run
  end

  task :results_for_rating do
    TournamentResultsFetcher.new(ids: rating_tournaments).run
  end

  task :results_for_recent, [:days] do |t, args|
    ids = recent_tournaments(days: args[:days].to_i)
    TournamentResultsFetcher.new(ids: ids).run
  end

  task :results_for_single_tournament, [:id] do |t, args|
    TournamentResultsFetcher.new(ids: [args[:id].to_i]).run
  end

  task :rosters_for_all do
    TournamentRostersFetcher.new(ids: all_tournaments).run
  end

  task :rosters_for_rating do
    TournamentRostersFetcher.new(ids: rating_tournaments).run
  end

  task :rosters_for_recent, [:days] do |t, args|
    ids = recent_tournaments(days: args[:days].to_i)
    TournamentRostersFetcher.new(ids: ids).run
  end

  task :rosters_for_single_tournament, [:id] do |t, args|
    TournamentRostersFetcher.new(ids: [args[:id].to_i]).run
  end
end

namespace :seasons do
  task :fetch_all do
    SeasonsImporter.new.run
  end
end