# == Schema Information
#
# Table name: qbo_clients
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  token              :string
#  secret             :string
#  realm_id           :integer
#  token_expires_at   :datetime
#  reconnect_token_at :datetime
#  created_at         :datetime
#  updated_at         :datetime
#

class QboClient < ActiveRecord::Base
  belongs_to :user
end
