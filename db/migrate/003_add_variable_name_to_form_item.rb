class AddVariableNameToFormItem < ActiveRecord::Migration
  class FormItem < ActiveRecord::Base; end
  def self.up
    add_column :form_items, :variable_name, :string, :default => "", :null => false
    FormItem.reset_column_information
    FormBuilder.get_classes  # Needed so the following statement includes all known subclasses... Rails sucks!
    FormControl.find(:all).each do |fi|
      fi.save!
    end
  end

  def self.down
    remove_column :form_items, :variable_name
  end
end
