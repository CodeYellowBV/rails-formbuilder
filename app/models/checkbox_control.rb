class CheckboxControl < ListControl
  has_properties :max => ["Maximum selected", "0"], :min => ["Minimum selected", "0"]

  alias_method :parse_max_property_value, :parse_integer_value
  alias_method :parse_min_property_value, :parse_integer_value

  def parse_value(value)
    super
    min = self.get_property_value(:min)
    max = self.get_property_value(:max)
    raise TypeError, "You must select at least #{min} options" if value.length < min
    raise TypeError, "You cannot select more than #{max} options" if max > 0 && value.length > max
    value
  end

  def self.concrete_item?; true; end
end
