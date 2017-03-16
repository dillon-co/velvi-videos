Aws.config.update({
  region: 'us-west-2',
  credentials: Aws::Credentials.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY']),
})

S3_BUCKET = Aws::S3::Resource.new.bucket('velvi-video-bucket')
