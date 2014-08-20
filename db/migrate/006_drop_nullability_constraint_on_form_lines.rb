class DropNullabilityConstraintOnFormLines < ActiveRecord::Migration
  # This migration is required because acts_as_list seems to generate an update 
  # that sets all positions to NULL when destroying models
  def self.up
    change_column :form_lines, :position, :integer, :default => 0, :null => true
  end

  def self.down
    change_column :form_lines, :position, :integer, :default => 0, :null => false
  end
end
