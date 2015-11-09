class CreateCodePipelines < ActiveRecord::Migration
  def change
    create_table :code_pipelines do |t|
      t.string :name
      t.string :github_owner
      t.string :repo
      t.string :hub
      t.references :cloud, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
