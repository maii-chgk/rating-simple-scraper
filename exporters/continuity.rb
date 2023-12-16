# frozen_string_literal: true

require 'google_drive'
require_relative '../db'
require_relative '../logger'

SPREADSHEET_ID = '1vBujFsh0p-gW4FOgOxBspKlU-nWED7b6BuSFP2ZO02c'

TeamIDUpdate = Struct.new('TeamIDUpdate', :tournament_id, :tournament_title, :tournament_date,
                          :old_id, :old_team_name, :new_id, :new_team_name)

def export_wrong_team_ids
  logger = Loggable.logger
  tournaments = tournaments_after(Time.new(2021, 9, 9))
  logger.info "checking #{tournaments.count} tournaments"

  headers = ['ID турнира', 'Турнир', 'Дата',
             'Неправильный ID команды', 'Неправильная команда',
             'Правильный ID команды', 'Правильная команда']
  exporter = SpreadsheetExporter.new(SPREADSHEET_ID, headers)
  exporter.write_headers!

  tournaments.each_with_index do |tournament, i|
    logger.info "processing tournament #{i + 1}/#{tournaments.count}" if (i + 1) % 10 == 0
    ids_to_update = TournamentChecker.new(tournament).wrong_ids
    logger.info "found #{ids_to_update.size} wrong teams ids in #{tournament[:title]}" unless ids_to_update.empty?
    exporter.write_rows!(ids_to_update)
  end
end

class SpreadsheetExporter
  def initialize(sheet_id, headers)
    session = GoogleDrive::Session.from_service_account_key('service-account.json')
    @sheet = session.spreadsheet_by_key(sheet_id).worksheets[0]
    @headers = headers
    write_headers!
  end

  def write_headers!
    @headers.each_with_index { |header, index| @sheet[1, index + 1] = header }
    @sheet.save
  end

  def write_rows!(rows)
    rows_count = @sheet.num_rows + 1
    rows.each do |row|
      row.each_with_index do |cell, index|
        cell.gsub!('__ROW_NUMBER__', rows_count.to_s) if cell.respond_to? :gsub

        @sheet[rows_count, index + 1] = cell
      end
      rows_count += 1
    end
    @sheet.save
  end
end

class TournamentChecker
  FIRST_DATE_OF_2021_RULES = Time.new(2021, 8, 28)
  FIRST_DATE_OF_2022_RULES = Time.new(2022, 11, 18)

  def initialize(tournament)
    @id = tournament[:id]
    @end_date = tournament[:end_datetime]
    @release_date = next_thursday(@end_date)
    @title = tournament[:title]
  end

  def next_thursday(date)
    date = date.to_date
    date = date.next_day until date.thursday?
    date
  end

  def wrong_ids
    players = fetch_tournament_rosters(@id)

    rosters = players.each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, hash|
      hash[row[:team_id]] << row[:player_id]
    end

    rosters.map do |team_id, team_players|
      deduce_team_id(team_id, team_players)
    end.compact
  end

  def deduce_team_id(team_id, players)
    base_teams = fetch_base_teams(players:, date: @release_date)
    return if base_teams.empty?

    counts = base_teams.tally.sort_by { |_team, count| -count }
    probable_base_team, base_team_player_count = counts.first

    # skip if a top team is already correctly assigned
    return if probable_base_team == team_id
    # skip if no base team has 3 representatives
    return if base_team_player_count < 3
    # or if two teams have 4 or more (that is, the second largest value is 4 or more)
    return if counts[1] && counts[1][1] >= 4

    return unless has_continuity?(base_team_player_count, players.size - base_team_player_count)

    build_team_id_update(team_id, probable_base_team)
  end

  def build_team_id_update(old_id, new_id)
    old_team_name = fetch_tournament_team_name(tournament_id: @id, team_id: old_id)
    new_team_name = fetch_base_team_name(team_id: new_id)
    tournament_title = "=HYPERLINK(CONCAT(\"https://rating.chgk.info/tournament/\", A__ROW_NUMBER__), \"#{@title}\")"
    TeamIDUpdate.new(tournament_id: @id,
                     tournament_date: @end_date.strftime('%Y-%m-%d'),
                     tournament_title:,
                     old_id:, old_team_name:,
                     new_id:, new_team_name:)
  end

  def has_continuity?(base_players, legionnaires)
    if @end_date >= FIRST_DATE_OF_2022_RULES
      (base_players >= 3) && (legionnaires < base_players) && (legionnaires <= 3)
    else
      base_players >= 4
    end
  end
end

started = Time.now
export_wrong_team_ids
puts "started at #{started}, finished at #{Time.now}"
