require 'rails/generators'

class ActsAsOrganizable::TaggableMigrationGenerator < Rails::Generators::Base
  def self.source_root
    # source root must return path to where templates are stored
     @source_root ||= File.join(File.dirname(__FILE__), '../templates')
  end
  
  
  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_migration_file
    template 'create_taggables.rb', "db/migrate/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_create_taggables.rb"
  end
  
end