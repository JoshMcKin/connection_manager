class TestDB
  def self.yml(driver='sqlite')
    YAML::load(File.open(File.join(File.dirname(__FILE__),'..',"#{driver}_database.yml")))
  end

  def self.connect(driver='sqlite',logging=false)
    ActiveRecord::Base.configurations = yml(driver)
    ActiveRecord::Base.establish_connection('test')
    ActiveRecord::Base.logger = Logger.new(STDOUT) if logging
  end

  def self.clean
    [:foos,:fruits,:baskets,:fruit_baskets,:regions,:types].each do |t|
      DBSpecManagement.connection.execute("DELETE FROM #{t.to_s}")
    end
  end
  #Class to clean tables
  class DBSpecManagement < ActiveRecord::Base
  end
end

#Put all the test migrations here
class TestMigrations < ActiveRecord::Migration
  # all the ups
  def self.up
    ActiveRecord::Base.establish_connection(:test)
    begin
      create_table "#{ActiveRecord::Base.schema_name}.foos" do |t|
        t.string :name
        t.integer :cm_user_id
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    begin
      create_table "#{ActiveRecord::Base.schema_name}.fruits" do |t|
        t.string :name
        t.integer :region_id
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    begin
      create_table "#{ActiveRecord::Base.schema_name}.baskets" do |t|
        t.string :name
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    begin
      create_table "#{ActiveRecord::Base.schema_name}.fruit_baskets" do |t|
        t.integer :fruit_id
        t.integer :basket_id
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    begin
      create_table "#{ActiveRecord::Base.schema_name}.regions" do |t|
        t.string :name
        t.integer :type_id
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    begin
      create_table "#{ActiveRecord::Base.schema_name}.types" do |t|
        t.string :name
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end

    ActiveRecord::Base.establish_connection(:cm_user_test)
    begin
      create_table :cm_users do |t|
        t.string :name
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end

    # Table is in more than 1 schema
    begin
      create_table "#{ActiveRecord::Base.schema_name}.types" do |t|
        t.string :name
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end

    ActiveRecord::Base.establish_connection(:test)
  end

  # all the downs
  def self.down(connection_name='test',user_connection_name='cm_user_test')
    ActiveRecord::Base.establish_connection(:test)
    [:foos,:fruits,:baskets,:fruit_baskets,:regions,:types].each do |t|
      begin
        drop_table t
      rescue => e
        puts "tables were not dropped: #{e}"
      end
    end
    ActiveRecord::Base.establish_connection(:cm_user_test)
    [ :cm_users, :types].each do |t|
      begin
        drop_table t
      rescue => e
        puts "tables were not dropped: #{e}"
      end
    end
    ActiveRecord::Base.establish_connection(:test)
  end
end
