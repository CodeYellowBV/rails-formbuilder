# A FormResponse contains filled-in values for a specific form's variables (as defined by FormControls).
class FormResponse < ActiveRecord::Base
  belongs_to :form
  has_many :form_item_values, :dependent => :destroy

  validates_presence_of :form

  def item_value(item)
    item = FormItem.find(item) unless item.is_a?(ActiveRecord::Base)
    val = self.form_item_values.detect {|v| v.form_item_id == item.id }
    if val
      if val.valid?
        val.parsed_value(item)
      else
        nil
      end
    else
      item.default_value
    end
  end

  def var_value(var)
    var = var.to_s # Should be a symbol on input
    item = self.form.form_items.detect {|i| i.variable_name == var }
    if item
      self.item_value(item)
    else
      nil
    end
  end

  def form_var_values
    result = {}
    self.form.form_items.each do |i|
      unless i.variable_name.blank?
        result[i.variable_name.to_sym] = self.item_value(i)
      end
    end
    result
  end

  # Is the given form item visible in the current form response?  This
  # depends on its "conditional" property and the visibility of all
  # its dependencies.
  def visible?(item, seen = [])
    seen += [item]
    item.dependencies(self.form).all? {|d| !seen.include?(d) and self.visible?(d, seen + [d])} and
      CQL.eval(item.get_property_value(:conditional), self.form_var_values)
  end
end
