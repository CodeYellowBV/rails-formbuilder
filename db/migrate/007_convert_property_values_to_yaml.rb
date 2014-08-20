class ConvertPropertyValuesToYaml < ActiveRecord::Migration
  # This migration is required because image_static can't save its binary images as text
  def self.up
    conn = ActiveRecord::Base.connection
    conn.transaction do
      conn.select_rows("SELECT id, value FROM form_item_properties").each do |row|
        val = YAML::dump(row[1])
        conn.execute(ActiveRecord::Base.sanitize_sql_array(["UPDATE form_item_properties SET value=? WHERE id=?", val, row[0]]))
      end
    end
  end

  def self.down
    conn = ActiveRecord::Base.connection
    conn.transaction do
      conn.select_rows("SELECT id, value FROM form_item_properties").each do |row|
        val = YAML.load(row[1])
        conn.execute(ActiveRecord::Base.sanitize_sql_array(["UPDATE form_item_properties SET value=? WHERE id=?", val, row[0]]))
      end
    end
  end
end
