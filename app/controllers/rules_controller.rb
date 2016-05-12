class RulesController < ApplicationController
  require 'roo'

  def import_rules
    user_id = current_user.id
    rules = Array.new
    sheet = Roo::Spreadsheet.open(params[:document].path)
    sheet.each(name: 'Rule Name', conditions: 'Rule Conditions', outputs: 'Rule Outputs') do |hash|
      rules.push(hash)
    end
    rules.delete_at(0)
    rules.each do |rule|
      #name
      name = rule[:name]
      #conditions
      parsed_conditions = JSON.parse rule[:conditions]
      #is and rule
      is_and_rule = parsed_conditions["isAndRule"]
      #actions
      parsed_actions = JSON.parse rule[:outputs]
      #payee
      payee_index = parsed_actions["ruleActions"].find_index{|h| h["actionType"] == 5 }
      payee_index.nil? ? payee = nil : payee = parsed_actions["ruleActions"][payee_index]["value"]
      #category
      category_index = parsed_actions["ruleActions"].find_index{|h| h["actionType"] == 0 }
      category_index.nil? ? category = nil : category = parsed_actions["ruleActions"][category_index]["value"]
      #memo
      memo_index = parsed_actions["ruleActions"].find_index{|h| h["actionType"] == 1 }
      memo_index.nil? ? memo = nil : memo = parsed_actions["ruleActions"][memo_index]["value"]
      #transfer_account_id
      transfer_account_index = parsed_actions["ruleActions"].find_index{|h| h["actionType"] == 7 }
      transfer_account_index.nil? ? transfer_account_id = nil : transfer_account_id = parsed_actions["ruleActions"][transfer_account_index]["value"]
      #create or update rule
      pre_existing_rule = Rule.where(name: name, user_id: user_id)
      if pre_existing_rule.any?
        rule = pre_existing_rule.last
      else
        rule = Rule.new
      end
      
      #assign values
      rule.user_id = user_id
      rule.name = name
      rule.is_and_rule = is_and_rule
      rule.payee = payee
      rule.category = category
      rule.memo = memo
      rule.is_qb_rule = true
      if rule.save
      #rule_details
        parsed_conditions["ruleConditions"].each do |c|
          pre_existing_detail = RuleDetail.where(rule_id: rule.id, code: c["ruleType"])
          if pre_existing_detail.any?
            rule_detail = pre_existing_detail.last
            rule_detail.value = c["value"]
          else 
            rule_detail = RuleDetail.new(rule_id: rule.id, code: c["ruleType"], value: c["value"])
          end
          if rule_detail.save
            puts "Rule detail code: #{c["ruleType"]} saved"
          else
            return render json: "rule saved but one or more rule details could not be saved"
          end
        end
        render json: "Rule and rule details were saved succesfully"
      else
        render json: "could not create rule"
      end           
    end
  end  
end