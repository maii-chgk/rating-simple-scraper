require_relative '../strategies/temp_table'

class TownsImporter < TempTableStrategy
  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      Integer :id
      String :title
    end
  end

  def id_name
    :id
  end

  def main_table_name
    :towns
  end
end
