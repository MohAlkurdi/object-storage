require "net/ftp"
require "fileutils"

module Storage
  class FtpAdapter
    def initialize(host:, username:, password:, root: "/")
      @host = host
      @username = username
      @password = password
      @root = root
    end

    def put(key:, data:)
      Net::FTP.open(@host, @username, @password) do |ftp|
        ftp.passive = true
        remote_path = File.join(@root, key)
        ensure_remote_dirs(ftp, File.dirname(remote_path))
        Tempfile.create("ftp-upload") do |file|
          file.binmode
          file.write(data)
          file.flush
          file.rewind
          ftp.putbinaryfile(file.path, remote_path)
        end
      end
      true
    end

    def get(key:)
      Net::FTP.open(@host, @username, @password) do |ftp|
        ftp.passive = true
        remote_path = File.join(@root, key)
        Tempfile.create("ftp-download") do |file|
          file.binmode
          ftp.getbinaryfile(remote_path, file.path)
          return File.binread(file.path)
        end
      end
    end

    private

    def ensure_remote_dirs(ftp, dir)
      parts = dir.split("/").reject(&:empty?)
      path = ""
      parts.each do |part|
        path += "/#{part}"
        begin
          ftp.mkdir(path)
        rescue Net::FTPPermError
        end
      end
    end
  end
end
