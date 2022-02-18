require_relative '../strategies/temp_table'

class TeamsImporter < TempTableStrategy
  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      Integer :id
      String :title
      Integer :town_id
    end
  end

  def id_name
    :id
  end

  def main_table_name
    :teams
  end
end
