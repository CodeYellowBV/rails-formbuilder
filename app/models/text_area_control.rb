# A bigger text control, with multiple lines
class TextAreaControl < TextControl
  has_properties(:maxlines => ["Maximum number of lines", "0"],
                 :rows => ["Rows to display", "10"],
                 :cols => ["Columns to display", "25"])

  alias_method :parse_maxlines_property_value, :parse_integer_value
  alias_method :parse_rows_property_value, :parse_integer_value
end
