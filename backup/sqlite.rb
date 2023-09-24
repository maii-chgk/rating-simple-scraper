# frozen_string_literal: true

require 'sqlite3'

require_relative '../logger'
require_relative '../db'
require_relative 'r2'

module Backup
  extend Loggable

  DB_TO_SQLITE_PATH = "/venv/bin/db-to-sqlite"

  def self.export_schema_to_sqlite(schema:, skip_tables:)
    logger.info "starting export to sqlite for #{schema}"
    file_name = "#{schema}.sqlite"
    skips = skip_tables.map { |table| "--skip #{table}" }.join(' ')
    backup_command = <<~PUBLIC
      #{DB_TO_SQLITE_PATH} "#{POSTGRES_CONNECTION_STRING}" #{file_name} \
        --all \
        --postgres-schema #{schema} \
        --progress \
        #{skips}
    PUBLIC

    logger.info "running db-to-sqlite for #{schema}"
    system backup_command
  end

  def self.export_table_to_sqlite(table_name:, sqlite_connection:)
    logger.info "exporting table #{table_name} to sqlite"

    schema, table = table_name.split(".").map(&:to_sym)
    postgres_table = Sequel.qualify(schema, table)

    batch_size = 1_000_000
    table_size = DB[postgres_table].count
    pages = table_size / batch_size

    columns = DB[postgres_table].columns

    (0..pages).each do |page_number|
      logger.info "exporting page ##{page_number} out of #{pages}"
      limit = batch_size
      offset = batch_size * page_number
      rows = DB[postgres_table].order(:id).limit(limit).offset(offset).map(columns)
      sqlite_connection[table].import(columns, rows)
    end
  end

end

task :backup_public_to_sqlite do
  skip_tables = %w[django_migrations django_admin_log django_content_type
                   django_session ar_internal_metadata
                   auth_group_permissions auth_group auth_permission auth_user auth_user_groups auth_user_user_permissions
                   schema_migrations ndcg models]

  Backup.export_schema_to_sqlite(schema: 'public', skip_tables:)
  Backup::R2.upload_file("public.sqlite")
  system "rm public.sqlite"
end

task :backup_b_to_sqlite do
  skip_tables = %w[django_migrations team_rating_by_player team_lost_heredity player_rating_by_tournament]

  Backup.export_schema_to_sqlite(schema: 'b', skip_tables:)
  sqlite_file = "b.sqlite"

  # As of Sept 2023, db-to-sqlite loads the whole table into memory before exporting it into sqlite.
  # To export player_rating_by_tournament, we would need at least 4GB of RAM.
  # For now, we export this table separately.
  Loggable.logger.info("exporting the player_rating_by_tournament table separately")
  sqlite_connection = Sequel.connect("sqlite://#{sqlite_file}")
  sqlite_connection.create_table! :player_rating_by_tournament do
    column :id, 'bigserial'
    Integer :player_id
    Integer :weeks_since_tournament
    Integer :cur_score
    Integer :release_id
    Integer :tournament_result_id
    Integer :initial_score
    Integer :tournament_id
  end
  Loggable.logger.info("sqlite table created")

  Backup.export_table_to_sqlite(table_name: 'b.player_rating_by_tournament', sqlite_connection:)
  Backup::R2.upload_file(sqlite_file)
  system "rm #{sqlite_file}"
end
