class TesseractController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_qb_service, only: [:create_purchase, :upload]
  require 'tesseract'
  require 'RMagick'
  def index
  end
  
  def uploader
  end
  
  def run
    file_name = random_file_name
    cordinate_x = params[:x_cordinate]
    cordinate_y = params[:y_cordinate]
    width = params[:width]
    height = params[:height]
    brightness = params[:brightness].to_i
    #%x(mkdir public/tessdir)
    
    e = Tesseract::Engine.new {|e|
      e.language  = :eng
      e.blacklist = '|'
    }
    
    (brightness < 220) ? brightness_increase = ((220 - brightness).to_f / 130) : brightness_increase = 0
    increased_brightness = 1 + brightness_increase
    
    puts "#{brightness}"
    puts "#{increased_brightness}"
    puts "#{params[:image].path}"
   
    image = Magick::ImageList.new(params[:image].path) do
      #self.format = 'jpg'
      self.quality = 100
      self.density = 250
    end
    
    image.write("public/uploads/#{file_name}.jpg")
    @lines = Array.new
    if image.size > 1
      counter = 0
      while counter < image.size do 
        page = RTesseract.read("public/uploads/#{file_name}-#{counter}.jpg") do |img|
          img = img.quantize(256,Magick::GRAYColorspace)
          #img = img.modulate(increased_brightness)
          img.write("public/uploads/#{file_name}-#{counter}.jpg")
          lines = e.lines_for("public/uploads/#{file_name}-#{counter}.jpg")
          lines.each do |line|
            @lines.push(line.to_s)
          end
          counter += 1
        end
      end
    else
      page = RTesseract.read("public/uploads/#{file_name}.jpg") do |img|
        img = img.quantize(256,Magick::GRAYColorspace)
        #img = img.modulate(increased_brightness)
        img.write("public/uploads/#{file_name}.jpg")
        lines = e.lines_for("public/uploads/#{file_name}.jpg")
        lines.each do |line|
          @lines.push(line.to_s)
        end
      end
    end

    amazon_template(@lines)
    
    #mix_block = RTesseract::Mixed.new("public/uploads/#{file_name}.jpg") do |image|
    #  image.area(cordinate_x, cordinate_y, width, height)
    #end

    #content1 = mix_block.to_s

    #%x(rm -Rf public/tessdir)
    #contents = image.to_s
    #@result = content1.first.gsub("\n", "<br />").html_safe
    #@result2 = contents
  end
  
  def create_expense(date, vendor_id, bank_account_id, doc_number, total, items={})
    @qbo_client = current_user.qbo_client
    
    entity_ref_id = vendor_id

    purchase = Quickbooks::Model::Purchase.new
    service = Quickbooks::Service::Purchase.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id
    
    products = get_items
    items.each do |item|
      line_item = Quickbooks::Model::PurchaseLineItem.new
      line_item.description = item[:description]
      line_item.amount = item[:amount]

      line_item.item_based_expense! do |line|
        existing_products = products.select {|product| product[:product].downcase == item[:product].downcase}
        if existing_products.any?
          item_ref = Quickbooks::Model::BaseReference.new(existing_products.first[:id])
        else
          create_item(item[:product])
          new_product = {product: @created_item.name, id: @created_item.id}
          products.push(new_product)
          item_ref = Quickbooks::Model::BaseReference.new(@created_item.id)
        end
        line.item_ref = item_ref
        line.unit_price = item[:price]
        line.quantity = item[:quantity]
      end
      purchase.line_items << line_item
    end

    entity_ref = Quickbooks::Model::BaseReference.new(entity_ref_id)
    purchase.entity_ref = entity_ref
    purchase.total = total
    purchase.payment_type = "Cash"
    purchase.doc_number = doc_number
    purchase.txn_date = date.strftime('%Y-%m-%d')
    account_ref = Quickbooks::Model::BaseReference.new(bank_account_id)
    purchase.account_ref = account_ref
    if @created_purchase = service.create(purchase)
      @id = @created_purchase.id
      vendor_service = Quickbooks::Service::Vendor.new
      vendor_service.access_token = set_qb_service
      vendor_service.company_id = @qbo_client.realm_id
      vendor = vendor_service.fetch_by_id(entity_ref_id)
      file_name = "#{vendor.display_name}-#{date}" 
      upload(@id, "Purchase", file_name)
      render_response(true, "Upload succesfull", 200)
    else 
      render_response(false, "something went wrong", 500)
    end
  end
  
  def amazon_template(lines)
    #order #
    order_line = lines.find { |e| /Details for Order/ =~ e }
    if order_line
      @order_number = order_line.split('#').last
    end
    # Grand Total
    total_line = lines.find { |e| /Order Total/ =~ e }
    if total_line
      @total = total_line.split('$').last
    end
    #items
    @items = Array.new
    items_header_lines = lines.each_index.select{|i| lines[i] =~ /Items Ordered/}
    items_subtotal_lines = lines.each_index.select{|i| lines[i] =~ /Item\(s\) Subtotal/}
    
    puts "#{items_header_lines}"
    
    if items_header_lines && items_subtotal_lines
      items_header_lines.each do |item|
        items_initial_index = item + 1
        items_ending_index = items_subtotal_lines.first
        items_subtotal_lines.shift
        i = items_initial_index
        while i < items_ending_index
          item_hash = Hash.new
          item_hash[:product] = "Amazon Purchase"
          item_hash[:amount] = lines[i].split("$").last
          description = lines[i].split("$").first
          if /of:/.match(description)
            item_hash[:description] = description.split("of:").last
            item_hash[:quantity] = description.split("of:").first
          else
            item_hash[:description] = description
            item_hash[:quantity] = 1
          end
          
          i += 1
          while /Sold by/i.match(lines[i]).nil?
            item_hash[:description] += " "+ lines[i]
            i += 1
          end
          
          item_hash[:seller] = lines[i].split("(").first
          i += 1
          item_hash[:condition] = lines[i]
          i += 1
          while /\$/.match(lines[i]).nil?
            item_hash[:condition] += " "+ lines[i]
            i += 1
          end
          @items.push(item_hash)
        end
      end
    end
    
    #date
    date_line = lines.find { |e| /Order Placed/ =~ e }
    digital_date_line = lines.find { |e| /Digital Order:/ =~ e }
    if date_line
      @date = Date.parse(date_line.split(':').last.strip)
    elsif digital_date_line
      @date = Date.parse(digital_date_line.split(':').last.strip)
    end
    
    create_expense(@date, 78, 42, @order_number, @total, @items)
    
  end
  
  def create_item(name)
    @qbo_client = current_user.qbo_client

    item = Quickbooks::Model::Item.new
    service = Quickbooks::Service::Item.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id

    item.name = name
    item.type = "Non Inventory"
    account_ref = Quickbooks::Model::BaseReference.new(78)
    item.expense_account_ref = account_ref

    if @created_item = service.create(item)
      puts "item created"
    else
      puts "item not created-- id : @created_item.id"
    end
  end
  
  def upload(reference_id, entity_type, file_name)
    @qbo_client = current_user.qbo_client
    meta = Quickbooks::Model::Attachable.new
    entity = Quickbooks::Model::BaseReference.new(reference_id)
    entity.type = entity_type
    meta.attachable_ref = Quickbooks::Model::AttachableRef.new(entity)
    meta.attachable_ref.include_on_send = true
    meta.file_name = file_name
    @upload_service = Quickbooks::Service::Upload.new
    @upload_service.access_token = set_qb_service
    @upload_service.company_id = @qbo_client.realm_id
    # args:
    #     local-path to file
    #     file mime-type
    #     (optional) instance of Quickbooks::Model::Attachable - metadata
    if params[:image]
      path = params[:image].path
      puts "#{params[:image].path}"
      result = @upload_service.upload(path, "application/pdf", meta)
    else
      puts"no path"
    end
  end
  
  private
  
  def get_items
    @qbo_client = current_user.qbo_client
    service = Quickbooks::Service::Item.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id
    items = service.query(nil, :page => 1, :per_page => 500)
    items_entries = items.entries
    items_array = Array.new
    items_entries.each do |item|
      entry = {product: item.name, id: item.id.to_i}
    items_array.push(entry)
    end
    return items_array
  end
  
  def set_qb_service
    client = current_user.qbo_client
    token = client.token
    secret = client.secret
    oauth_client = OAuth::AccessToken.new($qb_oauth_consumer, token, secret)
  end
  
  def render_response success, message, status
    output = {
      success: success,
      message: message,
      status: status
    }
    return render json: output.as_json
  end
  
  def random_file_name
    Digest::SHA1.hexdigest([Time.now, rand].join)[0..10]   
  end
end