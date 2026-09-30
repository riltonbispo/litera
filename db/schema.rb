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

ActiveRecord::Schema[8.1].define(version: 2026_09_30_215740) do
  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "author", null: false
    t.integer "first_publish_year"
    t.string "genre", null: false
    t.string "open_library_key"
    t.integer "cover_id"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "user_id, lower(title), lower(author), COALESCE(first_publish_year, -1)", name: "index_books_on_user_duplicate_key", unique: true
    t.index ["author"], name: "index_books_on_author"
    t.index ["created_at", "id"], name: "index_books_on_created_at_and_id"
    t.index ["first_publish_year"], name: "index_books_on_first_publish_year"
    t.index ["genre"], name: "index_books_on_genre"
    t.index ["open_library_key"], name: "index_books_on_open_library_key"
    t.index ["user_id"], name: "index_books_on_user_id"
    t.check_constraint "cover_id IS NULL OR cover_id >= 0", name: "books_cover_id_not_negative"
    t.check_constraint "length(trim(author)) > 0", name: "books_author_not_blank"
    t.check_constraint "length(trim(genre)) > 0", name: "books_genre_not_blank"
    t.check_constraint "length(trim(title)) > 0", name: "books_title_not_blank"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "books", "users"
end
