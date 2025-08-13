require "rails_helper"

RSpec.describe "V1::Blobs API", type: :request do
  let(:token) { "test-token" }
  let(:headers) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("API_TOKEN", nil).and_return(token)
    allow(ENV).to receive(:fetch).with("STORAGE_BACKEND", "db").and_return("db")
  end

  describe "POST /v1/blobs" do
    it "stores valid base64 and returns metadata" do
      payload = { id: "foo/123", data: Base64.strict_encode64("hello world") }
      post "/v1/blobs", params: payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq("foo/123")
      expect(Base64.strict_decode64(body["data"]).bytes).to eq("hello world".bytes)
      expect(body["size"]).to eq(11)
      expect(body["created_at"]).to be_present
      expect(StoredBlob.find_by(key: "foo/123")).to be_present
      expect(BlobBody.find_by(key: "foo/123")).to be_present
    end

    it "rejects invalid base64" do
      payload = { id: "bar", data: "not b64==" }
      post "/v1/blobs", params: payload.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires auth" do
      post "/v1/blobs", params: { id: "x", data: Base64.strict_encode64("x") }.to_json, headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /v1/blobs/:id" do
    it "retrieves stored blob" do
      payload = { id: "baz", data: Base64.strict_encode64("xyz") }
      post "/v1/blobs", params: payload.to_json, headers: headers
      get "/v1/blobs/baz", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq("baz")
      expect(Base64.strict_decode64(body["data"]).bytes).to eq("xyz".bytes)
      expect(body["size"]).to eq(3)
    end

    it "returns 404 for missing blob" do
      get "/v1/blobs/missing", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end

