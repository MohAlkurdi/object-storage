# Object Storage Service

An API to store and retrieve blobs

## Requirements

- Ruby and Bundler
- PostgreSQL, SQLite, or any Rails-supported DB

## Setup

```bash
bundle install
bin/rails db:setup
```

## Step-by-step (setup and use)

1. Install dependencies

```bash
bundle install
```

2. Set up the database

```bash
bin/rails db:setup
```

3. Configure environment

```bash
cp .env.example .env
export $(cat .env | xargs)
```

4. Choose a storage backend

- Database (default)

```bash
export STORAGE_BACKEND=db
```

- Local filesystem

```bash
export STORAGE_BACKEND=local
export STORAGE_DIR=/absolute/path/to/storage
mkdir -p "$STORAGE_DIR"
```

- AWS S3

```bash
export STORAGE_BACKEND=s3
export S3_ENDPOINT=https://s3.<region>.amazonaws.com
export S3_BUCKET=<your-bucket>
export S3_ACCESS_KEY=<your-access-key-id>
export S3_SECRET_KEY=<your-secret-key>
export S3_REGION=<region>
```

- FTP

```bash
export STORAGE_BACKEND=ftp
export FTP_HOST=<host>
export FTP_USERNAME=<user>
export FTP_PASSWORD=<pass>
export FTP_ROOT=/
```

5. Start the server

```bash
bin/rails s
```

6. Store a blob

```bash
TOKEN=$API_TOKEN
DATA=$(printf 'Hello Simple Storage World!' | base64)
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"paths/demo.txt\",\"data\":\"$DATA\"}" \
  http://localhost:3000/v1/blobs
```

7. Retrieve a blob

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/v1/blobs/paths/demo.txt
```

## Running

```bash
API_TOKEN=changeme STORAGE_BACKEND=db bin/rails s
```

## Authentication

All requests require a Bearer token header using `ENV["API_TOKEN"]`.

```http
Authorization: Bearer <token>
```

## API

- POST `/v1/blobs`

  - Body: `{ "id": "any_string_or_path", "data": "<base64>" }`
  - Responses:
    - 201 `{ id, data, size: "<bytes>", created_at }`
    - 401 `{ error: "unauthorized" }`
    - 422 `{ error: "invalid_base64" }`

- GET `/v1/blobs/:id` (supports slash ids)
  - 200 `{ id, data, size: "<bytes>", created_at }`
  - 401 `{ error: "unauthorized" }`
  - 404 `{ error: "not_found" }`

## Storage Backends

Select backend with `ENV["STORAGE_BACKEND"]` in { db | local | s3 | ftp }.

- db: stores blob bytes in table `blob_bodies` and metadata in `stored_blobs`.
- local: stores under `ENV["STORAGE_DIR"]` preserving id as a relative path.
- s3: raw HTTP AWS SigV4 (no SDK). Required env:
  - `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_REGION` (default `us-east-1`).
- ftp: passive mode. Required env:
  - `FTP_HOST`, `FTP_USERNAME`, `FTP_PASSWORD`, `FTP_ROOT` (default `/`).

Per-blob, the backend used at creation is recorded and automatically used on retrieval.

## Data Model

- `stored_blobs(key:string uniq, size:integer, backend:string, timestamps)`
- `blob_bodies(key:string uniq, data:binary, timestamps)`

Only metadata is kept in `stored_blobs`. Actual bytes are stored in the configured backend.

## Examples

Create a blob:

```bash
TOKEN=changeme
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id":"foo/bar.txt","data":"SGVsbG8gU2ltcGxlIFN0b3JhZ2UgV29ybGQh"}' \
  http://localhost:3000/v1/blobs | jq .
```

Fetch a blob:

```bash
TOKEN=changeme
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/v1/blobs/foo/bar.txt | jq .
```

## Testing

```bash
bundle exec rspec
```

## Notes

- S3 implementation signs requests using AWS SigV4 and uses only `Net::HTTP`.
- FTP adapter uses passive mode and creates intermediate directories when uploading.
