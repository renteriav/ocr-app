class Document < ActiveRecord::Base
  mount_uploader :image, DocumentUploader
  belongs_to :user
end