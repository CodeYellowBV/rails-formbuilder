# A TextControl is the simplest type of control.  It simply accepts text, with
# optionally a few constraints on length and such.
class TextControl < FormControl
  has_properties :minlength => ["The minimum number of characters", "0"],
                 :maxlength => ["The maximum number of characters", "0"],
                 :display_length => ["Number of characters to show at one time", "25"],
                 :default_value => ["The default value that's pre-filled", ""]

  def self.concrete_item?; true; end

  alias_method :parse_minlength_property_value, :parse_integer_value
  alias_method :parse_maxlength_property_value, :parse_integer_value
  alias_method :parse_display_length_property_value, :parse_integer_value

  def default_value
    self.get_property_value(:default_value)
  end
end
