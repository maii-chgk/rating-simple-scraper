# frozen_string_literal: true

require_relative 'r2'

task :backup do
  connection_string = ENV.fetch('CONNECTION_STRING', nil)
  local_backup_file_name = 'rating.backup'

  logger.info 'starting pg_dump'
  system "pg_dump -n public -n b -Fc -f #{local_backup_file_name} #{connection_string}"

  logger.info 'pg_dump complete, uploading to R2'
  Backup::R2.upload_file(local_backup_file_name)

  logger.info 'removing local copy'
  system "rm #{local_backup_file_name}"
  logger.info 'backup completed'
end
