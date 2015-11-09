class CreateCloudFormationStacks < ActiveRecord::Migration
  def change
    create_table :cloud_formation_stacks do |t|
      t.string :name
      t.references :cloud, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
