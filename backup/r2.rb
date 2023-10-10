# frozen_string_literal: true

module R2
  extend Loggable

  def self.client
    access_key_id = ENV.fetch('R2_ACCESS_KEY_ID', nil)
    secret_access_key = ENV.fetch('R2_SECRET_ACCESS_KEY', nil)
    cloudflare_account_id = ENV.fetch('R2_ACCOUNT_ID', nil)

    Aws::S3::Client.new(access_key_id:,
                        secret_access_key:,
                        endpoint: "https://#{cloudflare_account_id}.r2.cloudflarestorage.com",
                        region: 'auto')
  end

  def self.upload_file(filename)
    logger.info "uploading #{filename} to R2"
    r2_object = Aws::S3::Object.new('rating-backups', "#{Date.today}_#{File.basename(filename)}", client:)
    r2_object.upload_file(filename)

    logger.info 'uploaded to R2'
  end
end
