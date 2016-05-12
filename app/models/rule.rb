# == Schema Information
#
# Table name: rules
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  name                :string
#  is_qb_rule          :boolean
#  is_and_rule         :boolean
#  memo                :string
#  payee               :string
#  category            :string
#  transfer_account_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#

class Rule < ActiveRecord::Base
  belongs_to :user
  has_many :rule_details, dependent: :destroy
end
