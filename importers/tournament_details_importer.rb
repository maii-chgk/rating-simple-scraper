require_relative '../strategies/temp_table'

class TournamentDetailsImporter < TempTableStrategy
  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      Integer :id
      String :title
      DateTime :start_datetime
      DateTime :end_datetime
      DateTime :updated_at
      Integer :questions_count
      Integer :typeoft_id
      String :type
      TrueClass :maii_rating
      DateTime :maii_rating_updated_at
      TrueClass :maii_aegis
      DateTime :maii_aegis_updated_at
    end
  end

  def id_name
    :id
  end

  def main_table_name
    :tournaments_new
  end
end
