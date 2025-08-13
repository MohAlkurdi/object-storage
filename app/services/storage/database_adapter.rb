module Storage
  class DatabaseAdapter
    def put(key:, data:)
      BlobBody.create!(key: key, data: data)
    end

    def get(key:)
      record = BlobBody.find_by!(key: key)
      record.data
    end
  end
end

