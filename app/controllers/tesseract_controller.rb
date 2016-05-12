class TesseractController < ApplicationController
  require 'fileutils'
  require 'template'
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
    puts "Memory 1st pass:"
    puts `ps -o rss= -p #{$$}`  
    @document = current_user.documents.build(image: params[:image], user_id: current_user.id)
    file_name = random_file_name
    
    #brightness = params[:brightness].to_i
    
    #(brightness < 220) ? brightness_increase = ((220 - brightness).to_f / 130) : brightness_increase = 0
    #increased_brightness = 1 + brightness_increase

    #puts "#{params[:image].path}"
   
    image = Magick::ImageList.new(params[:image].path) do
      self.quality = 100
      self.density = 250
    end
    
    puts "Memory 2nd pass:"
    puts `ps -o rss= -p #{$$}`  
    
    image.write("#{file_name}.jpg")
    
    puts "Memory 3rd pass:"
    puts `ps -o rss= -p #{$$}`
    @lines = Array.new
    if image.size > 1
      counter = 0
      while counter < image.size do 
        #page = RTesseract.read("#{file_name}-#{counter}.jpg") do |img|
          #img = img.quantize(256,Magick::GRAYColorspace)
          #img = img.modulate(1.3)
          #img.write("#{file_name}-#{counter}.jpg")
          puts "Memory 4th pass:"
          puts `ps -o rss= -p #{$$}`
          text = RTesseract.new("#{file_name}-#{counter}.jpg", {psm: 6})
          text = text.to_s
          lines = text.split("\n")
          lines.each do |line|
            @lines.push(line) unless line == "" 
          end
          puts "Memory 5th pass:"
          puts `ps -o rss= -p #{$$}`
          FileUtils.rm "#{file_name}-#{counter}.jpg"
          #img.destroy!
          counter += 1
        #end
      end
      puts "#{@lines}"
    else
      #page = RTesseract.read("#{file_name}.jpg") do |img|
        #img = img.quantize(256,Magick::GRAYColorspace)
        #img = img.modulate(1.3)
        #img.write("#{file_name}.jpg")
        puts "Memory 4th pass:"
        puts `ps -o rss= -p #{$$}`
        text = RTesseract.new("#{file_name}.jpg", {psm: 6})
        text = text.to_s
        lines = text.split("\n")
        lines.each do |line|
          @lines.push(line) unless line == "" 
        end
        puts "Memory 5th pass:"
        puts `ps -o rss= -p #{$$}`
        FileUtils.rm "#{file_name}.jpg"
        #img.destroy!
      #end     
    end
    
    vendor = find_vendor(@lines)
    
    template = vendor.camelize.constantize.new
    template.get_values(@lines)
    
    @items = template.items
    @date = template.date
    @order_number = template.order_number
    @total = template.total
    
    #create_expense(@date, vendor, 42, "Amazon Purchase", @order_number, @total, @items)
  end
  
  def find_vendor(lines)
    vendors = ["Amazon", "bestbuy"]
    range = lines[0..9]
    range.each do |line|
      vendors.each do |v|
        if /#{v}/i.match(line)
          return v
        end
      end
    end
    nil
  end
  
  def create_expense(date, vendor_name, bank_account_id, product_name, doc_number, total, items={})
    @qbo_client = current_user.qbo_client

    purchase = Quickbooks::Model::Purchase.new
    service = Quickbooks::Service::Purchase.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id
    
    products = get_items
    existing_products = products.select {|product| product[:name].downcase == product_name.downcase}
    if existing_products.any?
      item_ref = Quickbooks::Model::BaseReference.new(existing_products.first[:id])
    else
      create_item(product_name)
      new_product = {product: @created_item.name, id: @created_item.id}
      item_ref = Quickbooks::Model::BaseReference.new(@created_item.id)
    end
    
    vendors = get_vendors
    existing_vendors = vendors.select {|vendor| vendor[:name].downcase == vendor_name.downcase}
    if existing_vendors.any?
      entity_ref_id = existing_vendors.first[:id]
    else
      create_vendor(vendor_name)
      new_vendor = {name: @created_vendor.display_name, id: @created_vendor.id}
      entity_ref_id = @created_vendor.id
    end
    
    accounts = get_bank_accounts
    bank_account_id = accounts.first[:id]
    
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
      puts "Upload succesful"
      render_response(true, "Upload succesfull", 200)
    else 
      puts "Upload unsuccesful"
      render_response(false, "something went wrong", 500)
    end
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
      puts "item not created"
    end
  end
  
  def create_vendor(name)
    @qbo_client = current_user.qbo_client

    vendor = Quickbooks::Model::Vendor.new
    service = Quickbooks::Service::Vendor.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id

    vendor.display_name = name

    if @created_vendor = service.create(vendor)
      puts "vendor created"
    else 
      puts "vendor not created"
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
      entry = {name: item.name, id: item.id.to_i}
      items_array.push(entry)
    end
    return items_array
  end
  
  def get_vendors
    @qbo_client = current_user.qbo_client
    service = Quickbooks::Service::Vendor.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id

    vendors = service.query(nil, :page => 1, :per_page => 500)
    vendors_entries = vendors.entries
    vendors = Array.new
    vendors_entries.each do |vendor|
      entry = {name: vendor.display_name, id: vendor.id.to_i}
      vendors.push(entry)
    end   
    return vendors
  end
  
  def get_bank_accounts
    @qbo_client = current_user.qbo_client
    service = Quickbooks::Service::Account.new
    service.access_token = set_qb_service
    service.company_id = @qbo_client.realm_id

    accounts = service.query(nil, :page => 1, :per_page => 500)
    @accounts = accounts.entries
    @expense_categories = Hash.new
    bank_accounts = Array.new
    @accounts.each do |acc|
      if acc.account_type
        if acc.account_type.downcase == "bank" || acc.account_type.downcase == "credit card"
          entry = {name: acc.name, id: acc.id.to_i}
          bank_accounts.push(entry)
        end   
      end
    end
    return bank_accounts
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