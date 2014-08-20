# An abstract control which manages lists of any kind.  Subclasses include
# Checkboxcontrol, RadioButtonControl or SelectionListControl.
class ListControl < FormControl
  has_properties :options => ["Options", ""]

  # Check the value against the known values in the parsed options property value
  def known_value?(v)
    option_name_for_value(v) != nil
  end

  # Find the (first) option which belongs to the specified value
  def option_name_for_value(v)
    def find_option(v, options)  # Silly Ruby, why do we need to repeat 'v' here?
      if options.is_a?(Hash) && options[:value] == v
        options[:name]
      elsif options.is_a?(Array)
        options.each do |o|
          opt = find_option(v, o)
          return opt if opt
        end
        nil
      else
        nil
      end
    end
    options = self.get_property_value(:options)
    find_option(v, options)
  end

  def default_value
    def find_default(options)  # Silly Ruby, why do we need to repeat 'v' here?
      if options.is_a?(Hash) && options[:default]
        [options[:value]]
      elsif options.is_a?(Array)
        options.map do |o|
          opt = find_default(o)
        end.flatten
      else
        []
      end
    end
    find_default(self.get_property_value(:options))
  end

  # Override this in cases like select, where optgroups can't be nested according
  # to the HTML spec.
  def nested_groups_ok?
    true
  end

  def parse_options_property_value(value)
    @@options_parser ||= OptionsParser.new()
    @@options_parser.parse(value, self.nested_groups_ok?)
  end

  # This is required to make the control aware of the fact that a value was sent,
  # even if zero options were selected
  def self.hidden_value_hack
    '&^%#@'
  end

  # Parse value method for all types of lists, be sure to call it because it
  # checks that the options are an Array and that the selected value is in the list
  # of allowed values.
  def parse_value(value)
    return [] if value.blank?
    raise TypeError, "Must be a list of options" unless value.is_a?(Array)
    value.delete(self.class.hidden_value_hack)
    raise TypeError, "You must select an option from the list!" unless value.all?{|v| self.known_value?(v) }
    value
  end
end
