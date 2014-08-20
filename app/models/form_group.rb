# A FormGroup is a group of FormLines.  This can be used recursively to created little 'subforms'.
# It should be displayed as a fieldset, for example.
class FormGroup < FormItem
  has_many :form_lines, :as => :line_group, :order => "position ASC", :dependent => :destroy

  def self.concrete_item?; true; end
end
