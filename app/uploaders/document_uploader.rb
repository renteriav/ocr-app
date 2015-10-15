# encoding: utf-8

class DocumentUploader < CarrierWave::Uploader::Base

  #Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
   #storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  
  #process :pdf_to_jpg_convert

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end
  #process :quality => 100
  # Create different versions of your uploaded files:

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
   def extension_white_list
     %w(jpg jpeg gif png pdf tif)
   end
   
   def pdf_to_jpg_convert
     image = Magick::ImageList.new(current_path) do
        self.format = 'jpg'
        self.quality = 100
        self.density = 250
      end
      #File.write("public/#{store_dir}/gif_preview.jpg", "")
      image.write "public/#{store_dir}/preview.jpg"
     #image.write("public/uploads/test.jpg")
     
     #image = MiniMagick::Image.open(current_path)
     #image.collapse! #get first gif frame
     #image.format "jpg"
     #File.write("public/#{store_dir}/gif_preview.jpg", "") #"touch" file
     #image.write "public/#{store_dir}/gif_preview.jpg"
   end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
  def set_content_type(*args)
    self.file.instance_variable_set(:@content_type, "image/jpg")
  end

end
