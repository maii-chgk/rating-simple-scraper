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

  attr_reader :release_date

  def initialize(tournament)
    @id = tournament[:id]
    @end_date = tournament[:end_datetime]
    @release_date = next_thursday(@end_date)
    @title = tournament[:title]
    @logger = Loggable.logger
  end

  def next_thursday(date)
    date = date.to_date
    date = date.next_day until date.thursday?
    date
  end

  def wrong_ids
    players = fetch_tournament_rosters(@id)

    @rosters = players.each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, hash|
      hash[row[:team_id]] << row[:player_id]
    end

    @id_changes = @rosters.map do |team_id, team_players|
      deduce_team_id(team_id, team_players)
    end.compact

    mark_same_id_assignments!
    mark_potential_duplicates!
    @id_changes
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

  def mark_same_id_assignments!
    # If two ids should be changed to the same one, we don’t change them:
    # it means that a team consciously split into two (see А.3.3.2)
    ids_tally = @id_changes.map(&:new_id).tally
    duplicate_ids = ids_tally.filter_map { |id, count| id if count >= 2 }
    @id_changes.each do |id_change|
      id_change.new_id = -1 if duplicate_ids.include?(id_change.new_id)
    end
  end

  def mark_potential_duplicates!
    # If a team is assigned to an id that already existed in the tournament,
    # we check if the already existing has continuity.
    # If it does, we should assign a second team to the same ID.
    # It it does not, we should get a new ID for the old team, and preserve reassignment.
    @id_changes.each do |id_change|
      team_id = id_change.new_id
      next unless @rosters.keys.include?(team_id)

      if is_continuous_to?(@rosters[team_id], team_id)
        id_change.new_id = -1
      else
        @id_changes << TeamIDUpdate.new(tournament_id: @id,
                                        tournament_date: @end_date.strftime('%Y-%m-%d'),
                                        tournament_title: @title,
                                        old_id: team_id,
                                        new_id: 0)
      end
    end
  end

  def is_continuous_to?(players, team_id)
    base_teams = fetch_base_teams(players:, date: @release_date)
    base_team_player_count = base_teams.count(team_id)

    has_continuity?(base_team_player_count, players.size - base_team_player_count)
  end

  def has_continuity?(base_players, legionnaires)
    if @end_date >= FIRST_DATE_OF_2022_RULES
      (base_players >= 3) && (legionnaires < base_players) && (legionnaires <= 3)
    else
      base_players >= 4
    end
  end
end
