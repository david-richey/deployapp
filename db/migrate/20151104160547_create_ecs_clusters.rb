class CreateEcsClusters < ActiveRecord::Migration
  def change
    create_table :ecs_clusters do |t|
      t.string :name
      t.string :hub
      t.references :cloud, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
