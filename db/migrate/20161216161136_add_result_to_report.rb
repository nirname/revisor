class AddResultToReport < ActiveRecord::Migration[5.0]
  def change
    add_column :reports, :data, :text
  end
end
