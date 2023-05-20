# frozen_string_literal: true

require_relative '../strategies/temp_table'

class PlayersImporter < TempTableStrategy
  def create_table(table_name)
    DB.create_table? table_name.to_sym do
      Integer :id
      String :first_name
      String :patronymic
      String :last_name
      DateTime :updated_at
    end
  end

  def id_name
    :id
  end

  def main_table_name
    :players
  end
end
