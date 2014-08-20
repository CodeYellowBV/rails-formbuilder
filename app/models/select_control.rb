class SelectControl < ListControl
  def self.concrete_item?; true; end

  def nested_groups_ok?; false; end

  def default_value
    default = super
    if default == [] # Empty list is not allowed
      nil
    else
      default
    end
  end

  def parse_value(value)
    super
    raise TypeError, "You can only select one option!" if value.length != 1
    value
  end
end
