# frozen_string_literal: true

require_relative '../strategies/temp_table'

class TournamentResultsImporter < TempTableStrategy
  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      column :id, 'bigserial'
      Integer :tournament_id
      Integer :team_id
      String :team_title
      Integer :team_city_id
      Integer :total
      Float :position
      Integer :old_rating
      Integer :old_rating_delta
      DateTime :updated_at
      Integer :points
      String :points_mask
    end
  end

  def id_name
    :tournament_id
  end

  def main_table_name
    :tournament_results
  end
end
