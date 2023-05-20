# frozen_string_literal: true

require_relative '../db'

class TempTableStrategy
  def self.import(data:, ids:)
    new(data, ids).import
  end

  def initialize(data, ids)
    @data = data
    @ids = ids
  end

  def import
    return if @data.empty? || @ids.empty?

    create_main_table
    create_temp_table
    import_data
    set_updated_at
    update_main_table
  end

  private

  def import_data
    DB[temp_table_name.to_sym].import(columns_to_import, flattened_data)
  end

  def set_updated_at
    DB[temp_table_name.to_sym].update(updated_at: DateTime.now)
  end

  def columns_to_import
    @data.first.keys.map(&:to_sym)
  end

  def flattened_data
    @data.map(&:values)
  end

  def create_temp_table
    create_table(temp_table_name)
  rescue Sequel::DatabaseDisconnectError
    retry
  end

  def create_main_table
    create_table(main_table_name)
  rescue Sequel::DatabaseDisconnectError
    retry
  end

  def update_main_table
    inserted_columns = [*columns_to_import, :updated_at].join(',')
    DB.transaction do
      DB.run("delete from #{main_table_name} where #{id_name} in (#{@ids.join(',')})")
      DB.run("insert into #{main_table_name} (#{inserted_columns}) (select #{inserted_columns} from #{temp_table_name})")
    end
  ensure
    DB.drop_table(temp_table_name)
  end

  def temp_table_name
    "#{main_table_name}_temp"
  end

  def create_table(table_name)
    raise NotImplementedError
  end

  def id_name
    raise NotImplementedError
  end

  def main_table_name
    raise NotImplementedError
  end
end
