Rails.application.routes.draw do
  get "tesseract", to: 'tesseract#index'
  post "tesseract/run", to: 'tesseract#run'
end
