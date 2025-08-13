require "fileutils"

module Storage
  class FilesystemAdapter
    def initialize(root:)
      @root = root
    end

    def put(key:, data:)
      path = absolute_path_for(key)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      File.binwrite(path, data)
      true
    end

    def get(key:)
      path = absolute_path_for(key)
      File.binread(path)
    end

    private

    def absolute_path_for(key)
      sanitized = key.to_s.gsub("..", "_")
      File.join(@root, sanitized)
    end
  end
end
