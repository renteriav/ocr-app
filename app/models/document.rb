# == Schema Information
#
# Table name: documents
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  image      :string
#  created_at :datetime
#  updated_at :datetime
#

class Document < ActiveRecord::Base
  mount_uploader :image, DocumentUploader
  belongs_to :user
end
