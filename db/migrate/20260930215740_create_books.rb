class CreateBooks < ActiveRecord::Migration[8.1]
  def up
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.integer :first_publish_year
      t.string :genre, null: false
      t.string :open_library_key
      t.integer :cover_id
      t.references :user, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_check_constraint :books, "length(trim(title)) > 0", name: "books_title_not_blank"
    add_check_constraint :books, "length(trim(author)) > 0", name: "books_author_not_blank"
    add_check_constraint :books, "length(trim(genre)) > 0", name: "books_genre_not_blank"
    add_check_constraint :books, "cover_id IS NULL OR cover_id >= 0", name: "books_cover_id_not_negative"

    add_index :books, :author
    add_index :books, :genre
    add_index :books, :first_publish_year
    add_index :books, :open_library_key
    add_index :books, [ :created_at, :id ]

    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_books_on_user_duplicate_key
      ON books (user_id, lower(title), lower(author), COALESCE(first_publish_year, -1))
    SQL
  end

  def down
    drop_table :books
  end
end
