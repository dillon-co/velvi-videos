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

ActiveRecord::Schema.define(version: 20180430210853) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string   "title"
    t.string   "nick_name"
    t.datetime "event_date"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "neural_nets", force: :cascade do |t|
    t.string   "title"
    t.string   "description"
    t.integer  "neural_net_type"
    t.integer  "number_of_layers"
    t.integer  "number_of_inputs"
    t.integer  "number_of_outputs"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "nodes", force: :cascade do |t|
    t.integer  "neural_net_id"
    t.string   "name"
    t.integer  "node_type"
    t.integer  "layer_number"
    t.integer  "node_input"
    t.integer  "cell_state"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["neural_net_id"], name: "index_nodes_on_neural_net_id", using: :btree
  end

  create_table "raffle_emails", force: :cascade do |t|
    t.string   "email",        null: false
    t.string   "name",         null: false
    t.integer  "raffle_count"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["email"], name: "index_raffle_emails_on_email", unique: true, using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.float    "money_in_account",       default: 0.0
    t.string   "youtube_uid"
    t.string   "youtube_token"
    t.string   "youtube_name"
    t.string   "youtube_refresh_token"
    t.string   "event_nick_name"
    t.boolean  "sponsored",              default: false
    t.boolean  "subscribed",             default: false
    t.integer  "num_followers"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "videos", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "music_url"
    t.string   "non_music_url"
    t.boolean  "done_editing",        default: false, null: false
    t.integer  "video_type"
    t.string   "uid"
    t.text     "description"
    t.integer  "event_id"
    t.boolean  "no_instagram_videos", default: false
    t.index ["event_id"], name: "index_videos_on_event_id", using: :btree
    t.index ["user_id"], name: "index_videos_on_user_id", using: :btree
  end

  create_table "weights", force: :cascade do |t|
    t.integer  "input_node_id"
    t.integer  "output_node_id"
    t.integer  "weight_value"
    t.integer  "weight_bias"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["input_node_id"], name: "index_weights_on_input_node_id", using: :btree
    t.index ["output_node_id"], name: "index_weights_on_output_node_id", using: :btree
  end

  add_foreign_key "videos", "events"
  add_foreign_key "videos", "users"
end
