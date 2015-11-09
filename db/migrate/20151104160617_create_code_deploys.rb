class CreateCodeDeploys < ActiveRecord::Migration
  def change
    create_table :code_deploys do |t|
      t.string :config_name
      t.string :app_name
      t.string :group_name
      t.string :key
      t.string :value
      t.references :cloud, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
