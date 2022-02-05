class TempTableStrategy
  def initialize(ids:)
    @ids = ids
  end

  def run
    create_main_table
    create_temp_table
    puts DateTime.now
    puts "Fetching data for #{@ids.size} ids"

    @ids.each do |id|
      data = fetch_data(id)
      puts "Saving #{data&.size} records for #{id}"
      processed_data = process_data(id, data)
      save_data(processed_data)
    end
    puts DateTime.now
    puts "Updating main table"
    update_main_table
    puts "Update completed"
    puts DateTime.now
  end

  def id_name
    raise NotImplementedError
  end

  def fetch_data(id)
    raise NotImplementedError
  end

  def process_data(id, data)
    raise NotImplementedError
  end

  def columns_to_import
    raise NotImplementedError
  end

  def save_data(data)
    DB[temp_table_name.to_sym].import(columns_to_import, data)
  end

  def create_table(table_name)
    raise NotImplementedError
  end

  def create_temp_table
    create_table(temp_table_name)
  end

  def create_main_table
    create_table(main_table_name)
  end

  def main_table_name
    raise NotImplementedError
  end

  def temp_table_name
    "#{main_table_name}_temp"
  end

  def update_main_table
    inserted_columns = columns_to_import.join(',')
    DB.transaction do
      DB.run("delete from #{main_table_name} where #{id_name} in (#{@ids.join(',')})")
      DB.run("insert into #{main_table_name} (#{inserted_columns}) (select #{inserted_columns} from #{temp_table_name})")
      DB.drop_table(temp_table_name)
    end
  end
end
