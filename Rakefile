# frozen_string_literal: true

require 'rapidjson/json_gem'
require 'honeybadger'
require 'aws-sdk-s3'
require 'date'

require_relative 'db'
require_relative './fetchers/towns'
require_relative './fetchers/teams'
require_relative './fetchers/players'
require_relative './fetchers/base_rosters'
require_relative './fetchers/tournament/details'
require_relative './fetchers/tournament/results'
require_relative './fetchers/tournament/rosters'
require_relative './standalone/season'

Honeybadger.configure do |config|
  config.exceptions.rescue_rake = true
end

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
  task :fetch_id_range, [:first_id, :number_of_ids] do |_t, args|
    last_id = if args[:number_of_ids].nil?
                max_team_id + 500
              else
                args[:first_id].to_i + args[:number_of_ids].to_i - 1
              end
    ids = (args[:first_id].to_i..last_id.to_i).to_a
    puts "fetching rosters for ids from #{args[:first_id]} to #{last_id}"
    BaseRostersFetcher.new(ids:).run
  end

  task :fetch_for_teams_in_rating_tournaments do
    BaseRostersFetcher.new(ids: teams_that_played_rating_tournaments).run
  end
end

namespace :tournaments do # rubocop:disable Metrics/BlockLength
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

  task :results_for_recent, [:days] do |_t, args|
    ids = recent_tournaments(days: args[:days].to_i)
    TournamentResultsFetcher.new(ids:).run
  end

  task :results_for_single_tournament, [:id] do |_t, args|
    TournamentResultsFetcher.new(ids: [args[:id].to_i]).run
  end

  task :rosters_for_all do
    TournamentRostersFetcher.new(ids: all_tournaments).run
  end

  task :rosters_for_rating do
    TournamentRostersFetcher.new(ids: rating_tournaments).run
  end

  task :rosters_for_recent, [:days] do |_t, args|
    ids = recent_tournaments(days: args[:days].to_i)
    TournamentRostersFetcher.new(ids:).run
  end

  task :rosters_for_single_tournament, [:id] do |_t, args|
    TournamentRostersFetcher.new(ids: [args[:id].to_i]).run
  end
end

namespace :seasons do
  task :fetch_all do
    SeasonsImporter.new.run
  end
end

task :backup do
  access_key_id = ENV.fetch('R2_ACCESS_KEY_ID', nil)
  secret_access_key = ENV.fetch('R2_SECRET_ACCESS_KEY', nil)
  cloudflare_account_id = ENV.fetch('R2_ACCOUNT_ID', nil)
  connection_string = ENV.fetch('CONNECTION_STRING', nil)
  local_backup_file_name = '/tmp/rating.backup'

  r2 = Aws::S3::Client.new(access_key_id:,
                           secret_access_key:,
                           endpoint: "https://#{cloudflare_account_id}.r2.cloudflarestorage.com",
                           region: 'auto')

  system "pg_dump -n public -n b -Fc -f #{local_backup_file_name} #{connection_string}"
  r2_object = Aws::S3::Object.new('rating-backups', "#{Date.today}_rating.backup", client: r2)
  r2_object.upload_file(local_backup_file_name)
  system "rm #{local_backup_file_name}"
end

task :vacuum do
  puts 'starting VACUUM FULL'
  DB.vacuum_full
  puts 'finished VACUUM FULL'
end

at_exit do
  Honeybadger.stop
end
