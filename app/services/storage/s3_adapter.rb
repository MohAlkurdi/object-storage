require "openssl"
require "base64"
require "net/http"
require "uri"
require "digest"

module Storage
  class S3Adapter
    def initialize(endpoint:, bucket:, access_key:, secret_key:, region: "us-east-1")
      @endpoint = endpoint
      @bucket = bucket
      @access_key = access_key
      @secret_key = secret_key
      @region = region
    end

    def put(key:, data:)
      path = "/#{@bucket}/#{key}"
      uri = URI.parse(@endpoint + path)

      request = Net::HTTP::Put.new(uri)
      request.body = data
      request["Content-Length"] = data.bytesize.to_s
      request["Content-Type"] = "application/octet-stream"
      set_aws_sigv4_headers!(request, uri, payload_sha256: Digest::SHA256.hexdigest(data))

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      response = http.request(request)
      unless response.code.to_i.between?(200, 299)
        raise "S3 PUT failed: #{response.code} #{response.body}"
      end
      true
    end

    def get(key:)
      path = "/#{@bucket}/#{key}"
      uri = URI.parse(@endpoint + path)
      request = Net::HTTP::Get.new(uri)
      set_aws_sigv4_headers!(request, uri, payload_sha256: Digest::SHA256.hexdigest(""))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      response = http.request(request)
      code = response.code.to_i
      return response.body if code.between?(200, 299)
      raise Errno::ENOENT if code == 404
      raise "S3 GET failed: #{response.code} #{response.body}"
    end

    private

    def set_aws_sigv4_headers!(request, uri, payload_sha256:)
      service = "s3"
      t = Time.now.utc
      amz_date = t.strftime("%Y%m%dT%H%M%SZ")
      datestamp = t.strftime("%Y%m%d")
      canonical_uri = uri.path
      canonical_querystring = ""
      canonical_headers = "host:#{uri.host}\n" \
                          "x-amz-content-sha256:#{payload_sha256}\n" \
                          "x-amz-date:#{amz_date}\n"
      signed_headers = "host;x-amz-content-sha256;x-amz-date"
      request["x-amz-date"] = amz_date
      request["x-amz-content-sha256"] = payload_sha256

      canonical_request = [
        request.method,
        canonical_uri,
        canonical_querystring,
        canonical_headers,
        signed_headers,
        payload_sha256
      ].join("\n")

      algorithm = "AWS4-HMAC-SHA256"
      credential_scope = "#{datestamp}/#{@region}/#{service}/aws4_request"
      string_to_sign = [
        algorithm,
        amz_date,
        credential_scope,
        Digest::SHA256.hexdigest(canonical_request)
      ].join("\n")

      signing_key = get_signature_key(@secret_key, datestamp, @region, service)
      signature = OpenSSL::HMAC.hexdigest("sha256", signing_key, string_to_sign)
      authorization_header = "#{algorithm} Credential=#{@access_key}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"
      request["Authorization"] = authorization_header
    end

    def sign(key, msg)
      OpenSSL::HMAC.digest("sha256", key, msg)
    end

    def get_signature_key(key, date_stamp, region_name, service_name)
      k_date = sign("AWS4" + key, date_stamp)
      k_region = sign(k_date, region_name)
      k_service = sign(k_region, service_name)
      sign(k_service, "aws4_request")
    end
  end
end
