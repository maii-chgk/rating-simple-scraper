require 'sequel'

connection_string = ENV.fetch('CONNECTION_STRING', 'postgres://localhost/postgres')
DB = Sequel.connect(connection_string)
