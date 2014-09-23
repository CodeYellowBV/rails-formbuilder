# A FormControl is a FormItem that is associated with a variable name.
# When a form is rendered, FormControls generate HTML controls which
# send a name/value pair to the server when submitted.
#
# Every value get stored as a FormItemValue when the form is submitted.
#
# FormControls can also have an explanatory description added to them.
# These descriptions are not the same as FormStatics because they
# can not be associated with the control, meaning they also cannot
# be displayed in context close to the FormControl.  They would belong
# semantically in another DIV, which means they're semantically separated.
class FormControl < FormItem
  has_properties :label => ["Label", proc {self.class.name.underscore.sub(/_control/, '')} ]

  validates_presence_of :variable_name, :message => N_("You must specify a variable name")
  # XXX This is broken.  Looks like it might be fixed in Rails 2.0
  validates_uniqueness_of :variable_name, :scope => :form_id, :message => N_("This variable name is already used on this form")

  before_validation :increase_variable_name

  def initialize(*args)
    super(*args)
  end

  def increase_variable_name
    self.variable_name = next_variable_name if self.variable_name.blank?
  end

  def default_value
    nil
  end

protected
  # Calculate the next variable name
  def next_variable_name
    FormBuilder.get_classes  # Needed so the following statement includes all known subclasses... Rails sucks!
    last_item = FormControl.where(["form_id = ? AND variable_name LIKE 'variable%'", form.id]).order("id DESC").first
    if !last_item  # This is the first control on the form
      "variable1"
    elsif (num = last_item.variable_name.match(/[0-9]+$/))
      last_item.variable_name.sub(num[0], '') + (num[0].to_i + 1).to_s
    else
      "var_id_#{last_item.id + 1}"
    end
  end
end
