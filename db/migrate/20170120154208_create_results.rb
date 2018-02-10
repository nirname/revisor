class CreateResults < ActiveRecord::Migration[5.0]
  def change
    create_table :results do |t|
      t.string :code
      t.jsonb :params
      t.text :data

      t.timestamps
    end
  end
end
