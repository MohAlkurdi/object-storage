module Storage
  class Client
    def self.adapter
      backend = ENV.fetch("STORAGE_BACKEND", "db").to_s.downcase
      for_backend(backend)
    end

    def self.for_backend(backend)
      backend = backend.to_s.downcase
      case backend
      when "db"
        Storage::DatabaseAdapter.new
      when "local"
        root = ENV.fetch("STORAGE_DIR")
        Storage::FilesystemAdapter.new(root: root)
      when "s3"
        endpoint = ENV.fetch("S3_ENDPOINT")
        bucket = ENV.fetch("S3_BUCKET")
        access_key = ENV.fetch("S3_ACCESS_KEY")
        secret_key = ENV.fetch("S3_SECRET_KEY")
        region = ENV.fetch("S3_REGION", "us-east-1")
        Storage::S3Adapter.new(endpoint: endpoint, bucket: bucket, access_key: access_key, secret_key: secret_key, region: region)
      when "ftp"
        host = ENV.fetch("FTP_HOST")
        username = ENV.fetch("FTP_USERNAME")
        password = ENV.fetch("FTP_PASSWORD")
        root = ENV.fetch("FTP_ROOT", "/")
        Storage::FtpAdapter.new(host: host, username: username, password: password, root: root)
      else
        raise "Unknown storage backend: #{backend}"
      end
    end
  end
end
