# frozen_string_literal: true

require 'sqlite3'

require_relative '../logging'
require_relative '../db'
require_relative 'r2'

class Backup
  include Loggable

  DB_TO_SQLITE_PATH = '/venv/bin/db-to-sqlite'
  TABLE_EXPORT_BATCH_SIZE = 1_000_000

  def initialize(schema, tables_to_skip, tables_to_export_separately = nil)
    @schema = schema
    @tables_to_skip = tables_to_skip
    @tables_to_export_separately = tables_to_export_separately || []
    @sqlite_file_path = "#{@schema}.sqlite"
    @sqlite_connection = Sequel.connect("sqlite://#{@sqlite_file_path}")
  end

  def run
    export_schema
    export_additional_tables
    upload_to_r2
    delete_file
  end

  def export_schema
    logger.info "starting export to sqlite for #{@schema}"
    skips = @tables_to_skip.map { |table| "--skip #{table}" }.join(' ')
    backup_command = <<~PUBLIC
      #{DB_TO_SQLITE_PATH} "#{POSTGRES_CONNECTION_STRING}" #{@sqlite_file_path} \
        --all \
        --postgres-schema #{@schema} \
        --progress \
        #{skips}
    PUBLIC

    logger.info "running db-to-sqlite for #{@schema}"
    system backup_command
  end

  def export_additional_tables
    logger.info "exporting additional tables"
    @tables_to_export_separately.each do |table, definition|
      create_table(definition)
      export_table(table)
    end
  end

  def create_table(definition)
    @sqlite_connection.run(definition)
  end

  def export_table(sqlite_table)
    logger.info "exporting table #{sqlite_table} to sqlite"
    postgres_table = Sequel.qualify(@schema, sqlite_table)
    table_size = DB[postgres_table].count
    pages = table_size / TABLE_EXPORT_BATCH_SIZE
    columns = DB[postgres_table].columns

    (0..pages).each do |page_number|
      logger.info "exporting page ##{page_number} out of #{pages}"
      limit = TABLE_EXPORT_BATCH_SIZE
      offset = TABLE_EXPORT_BATCH_SIZE * page_number
      rows = DB[postgres_table].order(:id).limit(limit).offset(offset).map(columns)
      @sqlite_connection[sqlite_table.to_sym].import(columns, rows)
    end
    logger.info "exported #{sqlite_table}"
  end

  def upload_to_r2
    R2.upload_file(File.expand_path(@sqlite_file_path))
  end

  def delete_file
    system "rm #{@sqlite_file_path}"
  end
end

task :backup_public_to_sqlite do
  skip_tables = %w[django_migrations django_admin_log django_content_type
                   django_session ar_internal_metadata
                   auth_group_permissions auth_group auth_permission auth_user auth_user_groups auth_user_user_permissions
                   schema_migrations ndcg models]

  Backup.new('public', skip_tables).run
end

task :backup_b_to_sqlite do
  skip_tables = %w[django_migrations team_rating_by_player team_lost_heredity player_rating_by_tournament player_rating]

  # As of Sept 2023, db-to-sqlite loads the whole table into memory before exporting it into sqlite.
  # To export player_rating_by_tournament, we would need at least 4GB of RAM.
  # For now, we export this table separately.
  player_rating_by_tournament_definition = <<~SQL
    drop table if exists player_rating_by_tournament;
    create table player_rating_by_tournament(
      id                     bigserial,
      player_id              integer,
      weeks_since_tournament integer,
      cur_score              integer,
      release_id             integer,
      tournament_result_id   integer,
      initial_score          integer,
      tournament_id          integer
    );
  SQL

  player_rating_definition = <<~SQL
    drop table if exists player_rating;
    create table player_rating(
      id            bigserial,
      player_id     integer,
      rating        integer,
      rating_change integer,
      release_id    integer,
      place         numeric(7, 1),
      place_change  numeric(7, 1)
    );
  SQL

  Backup.new('b', skip_tables, [['player_rating_by_tournament', player_rating_by_tournament_definition],
                                ['player_rating', player_rating_definition]]).run
end
