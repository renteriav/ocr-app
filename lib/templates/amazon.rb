module Template
  class Amazon
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
      #create_expense(@date, "Amazon", 42, "Amazon Purchase", @order_number, @total, @items)
      #render_response(true, "Upload succesfull", 200)
    end
  end
end