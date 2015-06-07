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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150607113403) do

# Could not dump table "account" because of following StandardError
#   Unknown type 'acct_type_enum' for column 'acct_type'

  create_table "bankstatement", :primary_key => "stmt_id", :force => true do |t|
    t.integer  "acct_id",                                  :null => false
    t.date     "stmt_date",                                :null => false
    t.decimal  "balance",   :precision => 10, :scale => 2, :null => false
    t.datetime "entered",                                  :null => false
  end

  add_index "bankstatement", ["acct_id", "stmt_date"], :name => "uniq_acct_date", :unique => true
  add_index "bankstatement", ["acct_id"], :name => "acct_id_2"
  add_index "bankstatement", ["stmt_date"], :name => "stmt_date"

  create_table "budget_category", :primary_key => "budget_category_id", :force => true do |t|
    t.text    "category_name"
    t.decimal "annual_amount", :precision => 19, :scale => 2
  end

  create_table "classification", :primary_key => "classif_id", :force => true do |t|
    t.string "name", :limit => 50, :default => "", :null => false
  end

  add_index "classification", ["name"], :name => "uniq_classif_name", :unique => true

  create_table "entry", :primary_key => "entry_id", :force => true do |t|
    t.integer "trans_id",                                                :null => false
    t.integer "acct_id",                                                 :null => false
    t.string  "num",        :limit => 20
    t.decimal "amount",                   :precision => 10, :scale => 2, :null => false
    t.integer "user_id",                                                 :null => false
    t.integer "classif_id"
    t.integer "stmt_id"
    t.text    "memo"
  end

  add_index "entry", ["amount"], :name => "entry_amt"
  add_index "entry", ["num"], :name => "entry_num"

  create_table "fuser", :primary_key => "user_id", :force => true do |t|
    t.string  "fullname",        :limit => 50,                    :null => false
    t.string  "nickname",        :limit => 4,                     :null => false
    t.boolean "payment_default",               :default => false, :null => false
  end

  add_index "fuser", ["fullname"], :name => "user_fullname", :unique => true
  add_index "fuser", ["nickname"], :name => "user_nickname", :unique => true
  add_index "fuser", ["payment_default"], :name => "fuser_payment_default_excl"

# Could not dump table "gas" because of following StandardError
#   Unknown type 'vehicle' for column 'vehicle'

  create_table "institution", :primary_key => "inst_id", :force => true do |t|
    t.string "name", :limit => 50, :null => false
  end

  add_index "institution", ["name"], :name => "inst_name", :unique => true

  create_table "inventory", :id => false, :force => true do |t|
    t.integer "entry_id",      :null => false
    t.text    "memo"
    t.string  "serial_number"
    t.text    "manual_url"
    t.text    "model_number"
  end

  create_table "investment", :primary_key => "investment_id", :force => true do |t|
    t.string "symbol", :limit => 50
  end

# Could not dump table "investment_transaction" because of following StandardError
#   Unknown type 'investment_type_enum' for column 'type'

  create_table "payee", :primary_key => "payee_id", :force => true do |t|
    t.string   "name",    :limit => 50, :null => false
    t.text     "memo"
    t.datetime "entered",               :null => false
  end

  add_index "payee", ["name"], :name => "payee_name", :unique => true

  create_table "posted_transactions", :force => true do |t|
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.date     "sale_date"
    t.date     "post_date"
    t.decimal  "amount",               :precision => 10, :scale => 2, :null => false
    t.text     "reference_identifier"
    t.text     "type_identifier"
    t.text     "category"
    t.text     "memo"
    t.text     "person"
    t.integer  "account_id",                                          :null => false
    t.integer  "txn_id"
    t.integer  "stmt_id",                                             :null => false
  end

  add_index "posted_transactions", ["txn_id"], :name => "posted_transactions_uniq_txn_id", :unique => true

  create_table "transaction", :primary_key => "trans_id", :force => true do |t|
    t.date     "date",                        :null => false
    t.integer  "payee_id"
    t.boolean  "is_void",  :default => false, :null => false
    t.datetime "entered",                     :null => false
  end

  add_index "transaction", ["date"], :name => "trans_date"
  add_index "transaction", ["payee_id"], :name => "trans_payee"

  create_table "txn_importer_factories", :force => true do |t|
    t.text     "memo_regexp"
    t.integer  "user_id",         :null => false
    t.integer  "payee_id",        :null => false
    t.integer  "from_account_id", :null => false
    t.integer  "to_account_id",   :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "txn_importer_factories", ["from_account_id"], :name => "index_txn_importer_factories_on_from_account_id"
  add_index "txn_importer_factories", ["payee_id"], :name => "index_txn_importer_factories_on_payee_id"
  add_index "txn_importer_factories", ["to_account_id"], :name => "index_txn_importer_factories_on_to_account_id"
  add_index "txn_importer_factories", ["user_id"], :name => "index_txn_importer_factories_on_user_id"

end
