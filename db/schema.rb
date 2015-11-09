# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151105160604) do

  create_table "cloud_formation_stacks", force: :cascade do |t|
    t.string   "name"
    t.integer  "cloud_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "cloud_formation_stacks", ["cloud_id"], name: "index_cloud_formation_stacks_on_cloud_id"

  create_table "clouds", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "code_deploys", force: :cascade do |t|
    t.string   "config_name"
    t.string   "app_name"
    t.string   "group_name"
    t.string   "key"
    t.string   "value"
    t.integer  "cloud_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "code_deploys", ["cloud_id"], name: "index_code_deploys_on_cloud_id"

  create_table "code_pipelines", force: :cascade do |t|
    t.string   "name"
    t.string   "github_owner"
    t.string   "repo"
    t.string   "hub"
    t.integer  "cloud_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "code_pipelines", ["cloud_id"], name: "index_code_pipelines_on_cloud_id"

  create_table "ecs_clusters", force: :cascade do |t|
    t.string   "name"
    t.string   "hub"
    t.integer  "cloud_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "ecs_clusters", ["cloud_id"], name: "index_ecs_clusters_on_cloud_id"

  create_table "instances", force: :cascade do |t|
    t.string   "ids"
    t.integer  "cloud_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "instances", ["cloud_id"], name: "index_instances_on_cloud_id"

end
