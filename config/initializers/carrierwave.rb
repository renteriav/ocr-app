CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV['OCR_AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['OCR_AWS_SECRET_ACCESS_KEY'],
    #region: ENV['OCR_AWS_REGION']
  }
  config.fog_directory = ENV['OCR_AWS_BUCKET']
end