# A text control which only accepts whole integer input.
class IntegerControl < TextControl
  has_properties :min => ["Minimum value", "0"],
                 :max => ["Maximum value", "9999"], # Find a way to better express 'infinity'
                 :default_value => ["The default value that's pre-filled", "0"]

  alias_method :parse_min_property_value, :parse_integer_value
  alias_method :parse_max_property_value, :parse_integer_value
  alias_method :parse_default_value_property_value, :parse_integer_value

  def parse_value(value)
    result = parse_integer_value(value)
    # NOTE We can't make use of the default here... this may prove troublesome later on.  Think about this!
    min = self.get_property_value(:min)
    max = self.get_property_value(:max)
    raise TypeError, "The minimum value is #{min}" if min && result < min
    raise TypeError, "The maximum value is #{max}" if max && result > max
    value.to_i
  end
end
