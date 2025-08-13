class V1::BlobsController < V1::BaseController
  def create
    key = params.require(:id)
    b64 = params.require(:data)
    begin
      data = Base64.strict_decode64(b64)
    rescue ArgumentError
      render json: { error: "invalid_base64" }, status: :unprocessable_entity and return
    end
    adapter = Storage::Client.adapter
    adapter.put(key: key, data: data)
    record = StoredBlob.find_or_initialize_by(key: key)
    record.size = data.bytesize
    record.backend = ENV.fetch("STORAGE_BACKEND", "db")
    record.save!
    render json: serialize_blob(record: record, data: data), status: :created
  end

  def show
    key = params[:id]
    record = StoredBlob.find_by!(key: key)
    data = Storage::Client.for_backend(record.backend).get(key: key)
    render json: serialize_blob(record: record, data: data)
  rescue Errno::ENOENT
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def serialize_blob(record:, data:)
    {
      id: record.key,
      data: Base64.strict_encode64(data),
      size: data.bytesize.to_s,
      created_at: record.created_at.utc.iso8601
    }
  end
end
