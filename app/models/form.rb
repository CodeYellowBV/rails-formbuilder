# Form is the core class in the FormBuilder engine.  A Form holds all the
# FormLines that are to be shown to the user when he opens the form.
class Form < ActiveRecord::Base
  has_many :form_lines, :as => :line_group, :order => "position ASC", :dependent => :destroy
  has_many :form_responses, :dependent => :destroy
  has_many :form_items

  before_save :marshal
  after_save :unmarshal
  after_find :unmarshal

  def initialize(*args)
    super
    self.ruler_positions = []
  end

  def get_var_item(var)
    var = var.to_s # Should be a symbol on input
    self.form_items.detect {|i| i.variable_name == var }
  end

protected
  def unmarshal
    self.ruler_positions = YAML::load(self.ruler_positions) if self.ruler_positions != nil
  end

  def marshal
    self.ruler_positions = YAML::dump(self.ruler_positions) if self.ruler_positions != nil
  end
end
