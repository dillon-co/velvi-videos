class S3Store
  def initialize(file)
    @file = file
    @s3 = Aws::S3::Resource.new
    @bucket = @s3.bucket('velvi-video-bucket')
  end

  def store
    @obj = @bucket.object(filename)
    @obj.upload_file(@file, acl: 'public-read', content_type: 'video/mp4')
    self
  end

  def url
    @obj.public_url.to_s
  end

  private

  def filename
    @filename || File.basename(@file)
  end
end
