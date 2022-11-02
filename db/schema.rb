# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_11_02_011734) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "hosts", force: :cascade do |t|
    t.string "name"
  end

  create_table "indices", force: :cascade do |t|
    t.bigint "word_id"
    t.bigint "page_id"
    t.integer "frequency"
    t.index ["page_id"], name: "index_indices_on_page_id"
    t.index ["word_id", "page_id"], name: "word_page_id", unique: true
    t.index ["word_id"], name: "index_indices_on_word_id"
  end

  create_table "links", primary_key: ["page_id", "link_to"], force: :cascade do |t|
    t.bigint "page_id", null: false
    t.integer "link_to", null: false
    t.index ["page_id"], name: "index_links_on_page_id"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "host_id"
    t.string "name"
    t.string "title"
    t.float "page_rank"
    t.index ["host_id"], name: "index_pages_on_host_id"
  end

  create_table "words", force: :cascade do |t|
    t.string "token"
  end

  add_foreign_key "pages", "hosts"
end
