class TesseractController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_qb_service, only: [:create_purchase, :upload]
  #require 'tesseract'
  require 'RMagick'
  def index
    @document = Document.new
  end
  
  def uploader
  end
  
  def run
    @document = current_user.documents.build(image: params[:image], user_id: current_user.id)
    file_name = random_file_name
    cordinate_x = params[:x_cordinate]
    cordinate_y = params[:y_cordinate]
    width = params[:width]
    height = params[:height]
    brightness = params[:brightness].to_i
    #%x(mkdir public/tessdir)
    
    
    #e = Tesseract::Engine.new {|e|
    #  e.language  = :eng
    #  e.blacklist = '|'
    #}
    
    #respond_to do |format|
      #if @document.save
        #render_response(true, "Upload succesfull", 200)
        #else 
        #render_response(false, "something went wrong", 500)
        #end
      #end
    
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
    
    image.write("#{file_name}.jpg")
    @lines = Array.new
    if image.size > 1
      counter = 0
      while counter < image.size do 
        page = RTesseract.read("#{file_name}-#{counter}.jpg") do |img|
          img = img.quantize(256,Magick::GRAYColorspace)
          img = img.modulate(1.3)
          img.write("#{file_name}-#{counter}.jpg")
          #lines = e.lines_for("public/uploads/#{file_name}-#{counter}.jpg")
          text = RTesseract.new("#{file_name}-#{counter}.jpg", {psm: 6})
          text = text.to_s
          lines = text.split("\n")
          lines.each do |line|
            @lines.push(line) unless line == "" 
          end
          counter += 1
        end
      end
      puts "#{@lines}"
    else
      page = RTesseract.read("#{file_name}.jpg") do |img|
        img = img.quantize(256,Magick::GRAYColorspace)
        img = img.modulate(1.3)
        img.write("public/uploads/#{file_name}.jpg")
        #lines = e.lines_for("public/uploads/#{file_name}.jpg")
        text = RTesseract.new("#{file_name}.jpg", {psm: 6})
        text = text.to_s
        lines = text.split("\n")
        lines.each do |line|
          @lines.push(line) unless line == "" 
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
  
  def create_expense(date, vendor_id, bank_account_id, product_name, doc_number, total, items={})
    @qbo_client = current_user.qbo_client
    
    entity_ref_id = vendor_id

    purchase = Quickbooks::Model::Purchase.new
    service = Quickbooks::Service::Purchase.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id
    
    products = get_items
    existing_products = products.select {|product| product[:product].downcase == product_name.downcase}
    if existing_products.any?
      item_ref = Quickbooks::Model::BaseReference.new(existing_products.first[:id])
    else
      create_item(product_name)
      new_product = {product: @created_item.name, id: @created_item.id}
      item_ref = Quickbooks::Model::BaseReference.new(@created_item.id)
    end
    
    items.each do |item|
      line_item = Quickbooks::Model::PurchaseLineItem.new
      line_item.description = item[:description]
      line_item.amount = item[:amount]
      line_item.item_based_expense! do |line|
        line.item_ref = item_ref
        line.unit_price = item[:price]
        line.quantity = item[:quantity]
      end
      purchase.line_items << line_item
      
    end
    
    #txn_tax_detail = Quickbooks::Model::TransactionTaxDetail.new
    #tax_line = Quickbooks::Model::TaxLine.new
    #tax_line.detail_type = "TaxLineDetail"
    #tax_line.amount = 2.35
    #txn_tax_detail.total_tax = 2.34
    #txn_tax_detail.lines = [tax_line]
    #purchase.txn_tax_detail = txn_tax_detail
    

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
    #clean array
    lines.delete_if { |e| /http/ =~ e }
    lines.delete_if { |e| /PM/ =~ e }
    lines.delete_if { |e| /AM/ =~ e }
    #order #
    order_line = lines.find { |e| /order number/ =~ e }
    if order_line
      @order_number = order_line.split(':').last
      @order_number.gsub!("—", "-")
      @order_number.gsub!("O", "0")
    end
    # Grand Total
    total_line = lines.find { |e| /Order Total/ =~ e }
    if total_line
      @total = total_line.split('$').last
    end
    #shipping and handling
    shipping_lines = lines.each_index.select{|i| (lines[i] =~ /andling/) || (lines[i] =~ /andiing/) || (lines[i] =~ /and\|ing/)}
    if shipping_lines.any?
      @total_shipping = lines[shipping_lines.last].split("$").last
      @total_shipping.gsub!("g", "9")
      @total_shipping.gsub!("_", ".")
      if /\./.match(@total_shipping).nil?
        @total_shipping.insert(-3, '.')
      end
    end
    #Super saver discount
    saver_lines = lines.each_index.select{|i| lines[i] =~ /Super Saver/i}
    if saver_lines.any?
      @total_saver = lines[saver_lines.last].split("$").last
      if /\./.match(@total_saver).nil?
        @total_saver.insert(-3, '.')
      end
    end
    #giftcard
    giftcard_lines = lines.each_index.select{|i| (lines[i] =~ /Gift Card Amount/i)}
    if giftcard_lines.any?
      @total_giftcard = lines[giftcard_lines.last].split("$").last
      @total_giftcard.gsub!("g", "9")
      @total_giftcard.gsub!("_", ".")
      if /\./.match(@total_giftcard).nil?
        @total_giftcard.insert(-3, '.')
      end
    end
    #tax
    tax_lines = lines.each_index.select{|i| lines[i] =~ /Sales Tax/i}
    if tax_lines.any?
      @total_tax = (0).to_f
      tax_lines.each do |line|
        tax = lines[line].split('$').last
        if /\./.match(tax).nil?
          tax.insert(-3, '.')
        end
        @total_tax += tax.to_f
      end
    else
      tax_line = lines.find { |e| /Tax Collected/i =~ e }
      if tax_line
        @total_tax = tax_line.split('$').last.to_f
      end
    end
    #Rewards Points
    rewards_line = lines.find { |e| /Rewards Points/i =~ e }
    if rewards_line
      @total_rewards = rewards_line.split('$').last
    end
    #items
    @items = Array.new
    items_header_lines = lines.each_index.select{|i| lines[i] =~ /Items Ordered/}
    items_subtotal_lines = lines.each_index.select{|i| lines[i] =~ /tem\(s\) Subtota/}
    tax_lines = lines.each_index.select{|i| lines[i] =~ /Sales Tax/i}
    
    if items_header_lines && items_subtotal_lines
      items_header_lines.each do |item|
        items_initial_index = item + 1
        items_ending_index = items_subtotal_lines.first
        items_subtotal_lines.shift
        i = items_initial_index
        while i < items_ending_index
          item_hash = Hash.new
          item_hash[:price] = lines[i].split("$").last
          description = lines[i].split("$").first
          if /of:/i.match(description)
            description.gsub!(/of:/i, "of:")
            item_hash[:description] = description.split("of:").last
            item_hash[:quantity] = description.split("of:").first
          else
            item_hash[:description] = description
            item_hash[:quantity] = 1
          end
          item_hash[:amount] = sprintf "%.2f", item_hash[:quantity].to_f * item_hash[:price].to_f
          
          i += 1
          while /Sold by/i.match(lines[i]).nil?
            item_hash[:description] += " " + lines[i]
            i += 1
          end
          
          if /\(/.match(lines[i])
            item_hash[:seller] = lines[i].split("(").first
          else
            item_hash[:seller] = lines[i].split("seller").first
          end
          i += 1
          if /\$/.match(lines[i]).nil?
            item_hash[:condition] = lines[i]
            i += 1
          end
          while /\$/.match(lines[i]).nil?
            item_hash[:condition] += " "+ lines[i] unless /Eligible/i.match(lines[i]) || /Ship/i.match(lines[i]) || /Send/i.match(lines[i])
            i += 1
          end
          @items.push(item_hash)
        end
      end
    end
    
    if @total_shipping.to_f > 0
      item_hash = Hash.new
      item_hash[:description] = "Shipping and Handling"
      item_hash[:amount] = @total_shipping
      @items.push(item_hash)
    end
    if @total_saver
      item_hash = Hash.new
      item_hash[:description] = "Super Saver Discount"
      item_hash[:amount] = @total_saver.to_f * (-1)
      @items.push(item_hash)
    end
    if @total_rewards && @total_rewards.to_f > 0
      item_hash = Hash.new
      item_hash[:description] = "Rewards Points"
      item_hash[:amount] = @total_rewards.to_f * (-1)
      @items.push(item_hash)
    end
    if @total_giftcard && @total_giftcard.to_f > 0
      item_hash = Hash.new
      item_hash[:description] = "Gift Card"
      item_hash[:amount] = @total_giftcard.to_f * (-1)
      @items.push(item_hash)
    end
    if @total_tax && @total_tax.to_f > 0
      item_hash = Hash.new
      item_hash[:description] = "Sales Tax"
      item_hash[:amount] = sprintf "%.2f", @total_tax
      @items.push(item_hash)
    end
    
    #date
    date_line = lines.find { |e| /Order Placed/ =~ e }
    digital_date_line = lines.find { |e| /Digital Order:/ =~ e }
    if date_line
      @date = Date.parse(date_line.split(':').last.strip)
    elsif digital_date_line
      @date = Date.parse(digital_date_line.split(':').last.strip)
    end
    #create_expense(@date, 78, 42, "Amazon Purchase", @order_number, @total, @items)
    render_response(true, "Upload succesfull", 200)
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
  
  def document_params
    params.require(:document).permit(:user_id, :image)
  end  
  
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