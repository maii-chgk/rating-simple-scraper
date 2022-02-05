require 'sequel'

connection_string = ENV.fetch('CONNECTION_STRING', 'postgres://localhost/postgres')
DB = Sequel.connect(connection_string)
# DB = Sequel.connect('postgres://simple_scraper_cron:pv44H78XmNnuVwsfaNWu9gnKTyDy3Uq2DisABhQN4@104.248.17.45:5432/public')
