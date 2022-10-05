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

ActiveRecord::Schema[7.0].define(version: 2022_10_03_223819) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "hosts", force: :cascade do |t|
    t.string "name"
  end

  create_table "links", force: :cascade do |t|
    t.bigint "path_id"
    t.string "name"
    t.index ["path_id"], name: "index_links_on_path_id"
  end

  create_table "paths", force: :cascade do |t|
    t.bigint "host_id"
    t.string "name"
    t.index ["host_id"], name: "index_paths_on_host_id"
  end

  add_foreign_key "links", "paths"
  add_foreign_key "paths", "hosts"
end
