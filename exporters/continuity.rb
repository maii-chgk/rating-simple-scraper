# frozen_string_literal: true

require_relative '../db'
require_relative '../logging'

TeamIDUpdate = Struct.new('TeamIDUpdate', :tournament_id, :tournament_title, :tournament_date,
                          :old_id, :new_id)

class WrongTeamIDsExporter
  def initialize(start_date)
    @start_date = start_date
    @logger = Loggable.logger
  end

  def run
    maybe_create_table!

    tournaments = tournaments_after(@start_date)
    @logger.info "checking #{tournaments.count} tournaments"

    tournaments.each_with_index do |tournament, i|
      @logger.info "processing tournament #{i + 1}/#{tournaments.count}" if (i + 1) % 10 == 0

      delete_old_entries(tournament[:id])
      ids_to_update = TournamentChecker.new(tournament).wrong_ids
      next if ids_to_update.empty?

      @logger.info "found #{ids_to_update.size} wrong teams ids in #{tournament[:title]}"
      save_to_database(ids_to_update)
    end
  end

  def maybe_create_table!
    DB.create_table? :wrong_team_ids do
      column :id, 'bigserial'
      Integer :tournament_id
      Integer :old_team_id
      Integer :new_team_id
      DateTime :updated_at
    end
  end

  def delete_old_entries(tournament_id)
    DB[:wrong_team_ids].where(tournament_id:).delete
  end

  def save_to_database(ids_changes)
    updated_at = Time.now
    rows = ids_changes.map { |id| [id.tournament_id, id.old_id, id.new_id, updated_at] }
    DB[:wrong_team_ids].import(%i[tournament_id old_team_id new_team_id updated_at], rows)
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

    TeamIDUpdate.new(tournament_id: @id,
                     tournament_date: @end_date.strftime('%Y-%m-%d'),
                     tournament_title: @title,
                     old_id: team_id,
                     new_id: probable_base_team)
  end

  def has_continuity?(base_players, legionnaires)
    if @end_date >= FIRST_DATE_OF_2022_RULES
      (base_players >= 3) && (legionnaires < base_players) && (legionnaires <= 3)
    else
      base_players >= 4
    end
  end
end
