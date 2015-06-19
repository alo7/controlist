`rm test/test.sqlite3`
ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => "test/test.sqlite3",
  :pool=>5,
  :timeout=>5000)
class CreateSchema < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.integer :clazz_id
      t.integer :age
    end
    create_table :clazzs do |t|
      t.string :name
    end
  end
end
CreateSchema.new.change

