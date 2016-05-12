Rails.application.routes.draw do
  devise_for :users
  #root to: 'pro_advisors#sheet_upload'
  root to: 'tesseract#index'
  get "tesseract/uploader", to: 'tesseract#uploader'
  get "tesseract/image", to: 'tesseract#image'
  match "tesseract/run", to: 'tesseract#run', via: [:post, :get]
  
  get "rules", to: 'rules#index'
  match "rules/import_rules", to: 'rules#import_rules', via: [:post, :get]
  
  get "pro_advisors/sheet_upload", to: 'pro_advisors#sheet_upload'
  match "pro_advisors/import_advisors", to: 'pro_advisors#import_advisors', via: [:post, :get]
  get "pro_advisors/generate_csv", to: 'pro_advisors#generate_csv'
  resources :pro_advisors
  
  #quickbooks api 
  scope :quickbooks do
    get '/', to: 'quickbooks#index', as: :quickbooks_index
    get '/authenticate', to: 'quickbooks#authenticate', as: :quickbooks_authenticate
    get '/disconnect', to: 'quickbooks#disconnect', as: :quickbooks_disconnect
    get :oauth_callback, to: 'quickbooks#oauth_callback'
    get :success, to: 'quickbooks#success', as: :quickbooks_success
    get :new_customer, to: 'quickbooks#new_customer'
    post :create_vendor, to: 'quickbooks#create_vendor'
    get :new_vendor, to: 'quickbooks#new_vendor'
    post :create_customer, to: 'quickbooks#create_customer'
    get :purchase, to: 'quickbooks#purchase'
    post :create_purchase, to: 'quickbooks#create_purchase'
    get :sale, to: 'quickbooks#sale'
    post :create_sale, to: 'quickbooks#create_sale'  
    get :expense_categories, to: 'quickbooks#expense_categories', as: :quickbooks_expense_categories
    get :bank_accounts, to: 'quickbooks#bank_accounts', as: :quickbooks_bank_accounts
    get :vendors, to: 'quickbooks#vendors', as: :quickbooks_vendors
    get :payment_methods, to: 'quickbooks#payment_methods', as: :quickbooks_payment_methods
    get :items, to: 'quickbooks#items', as: :quickbooks_items
    get :customers, to: 'quickbooks#customers', as: :quickbooks_customers
    get :company_info, to: 'quickbooks#company_info', as: :quickbooks_company_info
    get :infusion, to: 'quickbooks#infusion', as: :quickbooks_infusion
    get :changed_entities, to: 'quickbooks#changed_entities', as: :quickbooks_changed_entities
    post :send_receipt_email, to: 'quickbooks#send_receipt_email', as: :quickbooks_send_receipt_email
  end
end
