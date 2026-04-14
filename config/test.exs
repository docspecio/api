import Config

# Use a small upload size limit in tests so the payload_too_large test
# can trigger a 413 without sending hundreds of megabytes.
config :docspec_api, max_upload_size: 1024
