class TestDB
  def self.yml
    YAML::load(File.open(File.join(File.dirname(__FILE__),'..',"database.yml")))
  end

  def self.connect(logging=false)
    ActiveRecord::Base.configurations = yml
    ActiveRecord::Base.establish_connection(:test)
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
    {:mysql_without_db => :test,:postgres_without_db => :test_other}.each do |build,key|
      ActiveRecord::Base.establish_connection(build)

      if build == :mysql_without_db
        begin
          ActiveRecord::Base.connection.execute("CREATE DATABASE IF NOT EXISTS cm_test;")
        rescue => e
          puts "Error creating database: #{e}"
        end
        begin
          ActiveRecord::Base.connection.execute("CREATE DATABASE IF NOT EXISTS cm_user_test;")
        rescue => e
          puts "Error creating database: #{e}"
        end
        ActiveRecord::Base.establish_connection(key)
      else
        begin
          ActiveRecord::Base.connection.execute("CREATE DATABASE cm_test;")
        rescue => e
          puts "Error creating database: #{e}"
        end
        ActiveRecord::Base.establish_connection(key)
        begin
          ActiveRecord::Base.connection.execute("CREATE SCHEMA cm_test;")
        rescue => e
          puts "Error creating schema: #{e}"
        end
      end

      begin
        create_table "cm_test.foos" do |t|
          t.string :name
          t.integer :cm_user_id
        end
      rescue => e
        puts "tables failed to create: #{e}"
      end
      begin
        create_table "cm_test.fruits" do |t|
          t.string :name
          t.integer :region_id
        end
      rescue => e
        puts "tables failed to create: #{e}"
      end
      begin
        create_table "cm_test.baskets" do |t|
          t.string :name
        end
      rescue => e
        puts "tables failed to create: #{e}"
      end
      begin
        create_table "cm_test.fruit_baskets" do |t|
          t.integer :fruit_id
          t.integer :basket_id
        end
      rescue => e
        puts "tables failed to create: #{e}"
      end
      begin
        create_table "cm_test.regions" do |t|
          t.string :name
          t.integer :type_id
        end
      rescue => e
        puts "tables failed to create: #{e}"
      end
      begin
        create_table "cm_test.types" do |t|
          t.string :name
        end
      rescue => e
        puts "tables failed to create: #{e}"
      end
    end
    ActiveRecord::Base.establish_connection(:cm_user_test)
    begin
      create_table 'cm_user_test.cm_users' do |t|
        t.string :name
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end

    # Table is in more than 1 schema
    begin
      create_table "cm_user_test.types" do |t|
        t.string :name
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    ActiveRecord::Base.establish_connection(:test)
  end

  # all the downs
  def self.down
    [:test, :test_other].each do |key|
      ActiveRecord::Base.establish_connection(key)
      [:foos,:fruits,:baskets,:fruit_baskets,:regions,:types].each do |t|
        begin
          drop_table "cm_test.#{t.to_s}"
        rescue => e
          puts "tables were not dropped: #{e}"
        end
      end
    end
    ActiveRecord::Base.establish_connection(:cm_user_test)
    [ :cm_users, :types].each do |t|
      begin
        puts drop_table "cm_user_test.#{t.to_s}"
      rescue => e
        puts "tables were not dropped: #{e}"
      end
    end
    ActiveRecord::Base.establish_connection(:test)
  end
end
