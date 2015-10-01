# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150925155824) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brands", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "profile_image"
    t.string   "logo_image"
    t.string   "company_name"
    t.string   "brand_phone"
    t.string   "brand_email"
    t.string   "brand_website"
    t.string   "line_one"
    t.string   "line_two"
    t.string   "keyword"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "brands", ["user_id"], name: "index_brands_on_user_id", using: :btree

  create_table "opro_auth_grants", force: :cascade do |t|
    t.string   "code"
    t.string   "access_token"
    t.string   "refresh_token"
    t.text     "permissions"
    t.datetime "access_token_expires_at"
    t.integer  "user_id"
    t.integer  "application_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "opro_auth_grants", ["access_token"], name: "index_opro_auth_grants_on_access_token", unique: true, using: :btree
  add_index "opro_auth_grants", ["code"], name: "index_opro_auth_grants_on_code", unique: true, using: :btree
  add_index "opro_auth_grants", ["refresh_token"], name: "index_opro_auth_grants_on_refresh_token", unique: true, using: :btree

  create_table "opro_client_apps", force: :cascade do |t|
    t.string   "name"
    t.string   "app_id"
    t.string   "app_secret"
    t.text     "permissions"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "opro_client_apps", ["app_id", "app_secret"], name: "index_opro_client_apps_on_app_id_and_app_secret", unique: true, using: :btree
  add_index "opro_client_apps", ["app_id"], name: "index_opro_client_apps_on_app_id", unique: true, using: :btree

  create_table "qbo_clients", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "token"
    t.string   "secret"
    t.integer  "realm_id"
    t.datetime "token_expires_at"
    t.datetime "reconnect_token_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qbo_clients", ["realm_id"], name: "index_qbo_clients_on_realm_id", unique: true, using: :btree

  create_table "relationships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "relationships", ["user_id"], name: "index_relationships_on_user_id", using: :btree

  create_table "shares", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "invitee_id"
    t.string   "share_code"
    t.string   "phone"
    t.datetime "accepted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shares", ["invitee_id"], name: "index_shares_on_invitee_id", unique: true, using: :btree
  add_index "shares", ["share_code"], name: "index_shares_on_share_code", unique: true, using: :btree
  add_index "shares", ["user_id"], name: "index_shares_on_user_id", using: :btree

  create_table "uploads", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "transaction_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uploads", ["user_id"], name: "index_uploads_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "roles_mask",             default: 4
    t.string   "first"
    t.string   "last"
    t.string   "phone"
    t.integer  "count_of_shares"
    t.string   "single_use_token"
    t.string   "share_token"
    t.integer  "count_of_uploads"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
