# == Schema Information
#
# Table name: pro_advisors
#
#  id           :integer          not null, primary key
#  first        :string
#  last         :string
#  company_name :string
#  email        :string
#  phone        :string
#  address      :string
#  city         :string
#  state        :string
#  zip_code     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class ProAdvisor < ActiveRecord::Base
  
end
