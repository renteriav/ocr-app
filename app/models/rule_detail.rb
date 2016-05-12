# == Schema Information
#
# Table name: rule_details
#
#  id         :integer          not null, primary key
#  rule_id    :integer
#  code       :integer
#  value      :string
#  created_at :datetime
#  updated_at :datetime
#

class RuleDetail < ActiveRecord::Base
  belongs_to :rule
end
