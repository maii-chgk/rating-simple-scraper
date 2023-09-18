# frozen_string_literal: true

require 'rapidjson/json_gem'
require 'honeybadger'
require 'aws-sdk-s3'
require 'date'

require_relative 'logger'
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

logger = Loggable.logger

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
    logger.info "fetching rosters for ids from #{args[:first_id]} to #{last_id}"
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

def r2_client
  access_key_id = ENV.fetch('R2_ACCESS_KEY_ID', nil)
  secret_access_key = ENV.fetch('R2_SECRET_ACCESS_KEY', nil)
  cloudflare_account_id = ENV.fetch('R2_ACCOUNT_ID', nil)

  Aws::S3::Client.new(access_key_id:,
                      secret_access_key:,
                      endpoint: "https://#{cloudflare_account_id}.r2.cloudflarestorage.com",
                      region: 'auto')
end

task :backup do
  connection_string = ENV.fetch('CONNECTION_STRING', nil)
  local_backup_file_name = '/tmp/rating.backup'

  logger.info 'starting pg_dump'
  system "pg_dump -n public -n b -Fc -f #{local_backup_file_name} #{connection_string}"

  logger.info 'pg_dump complete, uploading to R2'
  r2_object = Aws::S3::Object.new('rating-backups', "#{Date.today}_rating.backup", client: r2_client)
  r2_object.upload_file(local_backup_file_name)

  logger.info 'uploaded to R2, removing local copy'
  system "rm #{local_backup_file_name}"
  logger.info 'backup completed'
end

task :vacuum do
  logger.info 'starting VACUUM FULL'
  vacuum_full
  logger.info 'finished VACUUM FULL'
end

task :backup_to_sqlite do
  logger.info 'starting sqlite backup'

  connection_string = ENV.fetch('CONNECTION_STRING', nil)
  public_backup_file_name = '/tmp/rating_public.sqlite'
  b_backup_file_name = '/tmp/rating_b.sqlite'

  public_backup_command = <<~PUBLIC
    db-to-sqlite "#{connection_string}" #{public_backup_file_name} --all \
      --postgres-schema public \
      -p \
      --skip django_migrations --skip django_admin_log --skip django_content_type --skip django_session \
      --skip ar_internal_metadata --skip auth_group --skip auth_group_permissions --skip auth_permission \
      --skip auth_user --skip auth_user_groups --skip auth_user_user_permissions --skip ndcg --skip schema_migrations \
      --skip models
  PUBLIC

  b_backup_command = <<~B
      db-to-sqlite "#{connection_string}" #{b_backup_file_name} --all --postgres-schema b -p \
    --skip django_migrations --skip team_rating_by_player --skip team_lost_heredity
  B

  logger.info 'starting db-to-sqlite for schema public'
  system public_backup_command
  logger.info 'starting db-to-sqlite for schema b'
  system b_backup_command

  logger.info 'db-to-sqlite complete, uploading to R2'
  r2_object = Aws::S3::Object.new('rating-backups', "#{Date.today}_public.sqlite", client: r2_client)
  r2_object.upload_file(public_backup_file_name)
  r2_object = Aws::S3::Object.new('rating-backups', "#{Date.today}_b.sqlite", client: r2_client)
  r2_object.upload_file(b_backup_file_name)

  logger.info 'uploaded to R2, removing local copies'
  system "rm #{public_backup_file_name}"
  system "rm #{b_backup_file_name}"
  logger.info 'sqlite backup completed'
end

at_exit do
  Honeybadger.stop
end
