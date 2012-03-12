class TestDB
  def self.yml(driver='sqlite')
    YAML::load(File.open(File.join(File.dirname(__FILE__),'..',"#{driver}_database.yml")))
  end
  
  def self.connect(driver='sqlite')
    ActiveRecord::Base.configurations = yml(driver)
    ActiveRecord::Base.establish_connection('test') 
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
  def self.up(connection_name='test', user_connection_name='cm_user_test')  
    ActiveRecord::Base.establish_connection(connection_name) 
    begin
      create_table :foos do |t|
        t.string :name
        t.integer :user_id
      end 
      create_table :fruits do |t|
        t.string :name
        t.integer :region_id
        t.timestamps
      end
      create_table :baskets do |t|
        t.string :name
        t.timestamps
      end
      create_table :fruit_baskets do |t|
        t.integer :fruit_id
        t.integer :basket_id
        t.timestamps
      end
      create_table :regions do |t|
        t.string :name

        t.timestamps
      end
      create_table :types do |t|
        t.string :name
        t.timestamps
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    
    ActiveRecord::Base.establish_connection(user_connection_name)
    begin
      create_table :users do |t|
        t.string :name
      end
    rescue => e
      puts "tables failed to create: #{e}"
    end
    
    ActiveRecord::Base.establish_connection(connection_name)
  end
  
  # all the downs
  def self.down(connection_name='test',user_connection_name='cm_user_test')  
    ActiveRecord::Base.establish_connection(connection_name) 
    begin
      [:foos,:fruits,:baskets,:fruit_baskets,:regions,:types].each do |t|
        drop_table t 
      end
    rescue => e
      puts "tables were not dropped: #{e}"
    end
    ActiveRecord::Base.establish_connection(user_connection_name) 
    begin
      [:users].each do |t|
        drop_table t 
      end
    rescue => e
      puts "tables were not dropped: #{e}"
    end
    ActiveRecord::Base.establish_connection(connection_name)  
  end  
end 
