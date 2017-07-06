class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :title
      t.string :nick_name
      t.datetime :event_date
      t.text :description

      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
