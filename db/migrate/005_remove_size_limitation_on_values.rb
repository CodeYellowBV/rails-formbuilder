class RemoveSizeLimitationOnValues < ActiveRecord::Migration
  # We do this because users may have form item types that require really large binary data in the db
  # or perhaps just long pieces of text, either as property values or as response values.
  def self.up
    if adapter_name == "MySQL"
      # Sigh
      execute "ALTER TABLE form_item_values CHANGE value value LONGTEXT DEFAULT '' NOT NULL"
      execute "ALTER TABLE form_item_properties CHANGE value value LONGTEXT DEFAULT '' NOT NULL"
    else
      change_column :form_item_values, :value, :text, :default => "", :null => false
      change_column :form_item_properties, :value, :text, :default => "", :null => false
    end
  end

  def self.down
    change_column :form_item_values, :value, :string, :default => "", :null => false
    change_column :form_item_properties, :value, :string, :default => "", :null => false
  end
end
