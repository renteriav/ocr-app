class TesseractController < ApplicationController
  skip_before_filter :verify_authenticity_token 
  def index
  end
  def run

  	puts "In Run Controller"

    #jpg = Base64.decode64(params[:image])
    
    puts "Creating directory"
    %x(mkdir tessdir)

    puts "Saving image"
    #file = File.open("tessdir/sample.jpg",'wb')
  	#file.write jpg
    
    uploaded_io = params[:image]
    File.open(Rails.root.join('tessdir', uploaded_io.original_filename), 'wb') do |file|
    file.write(uploaded_io.read)
  end
	  
    puts "Starting tesseract"
    #%x(tesseract tessdir/sample.jpg tessdir/out)
    
    puts "Reading result"
    #file = File.open("tessdir/out.txt", "rb")
    #contents = file.read
    
    puts "removing tessdir"
    puts "#{Rails.root.join('public', 'uploads', uploaded_io.original_filename).to_s}"
    image = RTesseract.new(Rails.root.join('tessdir', uploaded_io.original_filename).to_s)
    contents = image.to_s
    %x(rm -Rf tessdir)
    render text: contents
  end
end