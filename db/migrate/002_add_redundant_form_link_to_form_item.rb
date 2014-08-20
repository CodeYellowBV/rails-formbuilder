class AddRedundantFormLinkToFormItem < ActiveRecord::Migration
  def self.up
    add_column :form_items, :form_id, :integer, :default => 0, :null => false
    # Copy from before_create code.  We're not just calling that as we don't know
    # if anything might be added to it in the future.
    FormItem.find(:all).each do |fi|
      parent = fi.form_line
      parent = parent.line_group until parent.is_a?(Form)
      fi.update_attribute_with_validation_skipping(:form_id, parent.id)
    end
  end

  def self.down
    remove_column :form_items, :form_id
  end
end
