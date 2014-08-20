class MultiSelectControl < SelectControl
  has_properties :max => ["Maximum selected", "0"], :min => ["Minimum selected", "0"],
                 :display_height => ["Number of option lines to show at one time", "5"]

  alias_method :parse_display_height_property_value, :parse_integer_value

  alias_method :parse_max_property_value, :parse_integer_value
  alias_method :parse_min_property_value, :parse_integer_value

  def self.concrete_item?; true; end

  def nested_groups_ok?; false; end

  def parse_value(value)
    # This code looks a lot like the code in CheckboxControl#parse_value.  It's not a proper
    # subclass, so we'll just have to sacrifice a bit of DRYness.
    # We will also copy the code from ListControl because super() will throw an exception.
    raise TypeError, "Must be a list of options" unless value.is_a?(Enumerable)
    raise TypeError, "You must select an option from the list!" unless value.all?{|v| self.known_value?(v) }
    min = self.get_property_value(:min)
    max = self.get_property_value(:max)
    raise TypeError, "You must select at least #{min} options" if value.length < min
    raise TypeError, "You cannot select more than #{max} options" if max > 0 && value.length > max
    value
  end
end
