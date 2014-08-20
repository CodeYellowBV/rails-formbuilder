class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table "form_item_properties", :force => true do |t|
      t.column "form_item_id", :integer, :default => 0,  :null => false
      t.column "name",         :string,  :default => "", :null => false
      t.column "value",        :string,  :default => "", :null => false
    end

    create_table "form_item_values", :force => true do |t|
      t.column "form_item_id",     :integer, :default => 0, :null => false
      t.column "form_response_id", :integer, :default => 0, :null => false
      t.column "value", :string, :default => "", :null => false  # nullable or not?
    end

    add_index "form_item_values", ["form_item_id", "form_response_id"], :name => "response_item", :unique => true

    create_table "form_items", :force => true do |t|
      t.column "type",         :string,  :default => "",  :null => false
      t.column "form_line_id", :integer, :default => 0,   :null => false
      t.column "offset",       :float,   :default => 0.0, :null => false
    end

    create_table "form_lines", :force => true do |t|
      t.column "line_group_id",   :integer, :default => 0,  :null => false
      t.column "line_group_type", :string,  :default => "", :null => false
      t.column "position",        :integer, :default => 0,  :null => false
    end

    # MySQL is too silly to handle constraint checks at the end of a transaction.  Nooo, it has to check after every frickin' statement...
    # And it has no SET CONSTRAINTS DEFERRED, which is standard SQL92, dammit!
    #add_index "form_lines", ["line_group_id", "line_group_type", "position"], :name => "line_group_positions", :unique => true

    create_table "form_responses", :force => true do |t|
      t.column "form_id", :integer, :default => 0, :null => false
      # More stuff
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "forms", :force => true do |t|
      t.column "name", :string, :default => "", :null => false
      t.column "ruler_positions", :string, :default => "", :null => false
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    add_index "forms", "created_at"
    add_index "forms", "updated_at"
  end

  def self.down
    drop_table "forms"
    drop_table "form_responses"
    drop_table "form_lines"
    drop_table "form_items"
    drop_table "form_item_values"
    drop_table "form_item_properties"
  end
end
