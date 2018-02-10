class AddShardToResult < ActiveRecord::Migration[5.0]
  def change
    add_column :results, :shard, :string
  end
end
