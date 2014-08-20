# A FormItem is an abstract class but it has its own table.
# It serves as the base class for FormControl, FormGroup and FormStatic.
# It has FormItemProperty links.  These can be either constraints or simply
# properties.  Each subclass knows about its own set of possible constraints and
# what to do with them.
class FormItem < ActiveRecord::Base
  has_many :form_item_properties, :dependent => :destroy # XXX this needs a unit test
  has_many :form_item_values, :dependent => :destroy     # XXX this needs a unit test
  belongs_to :form_line
  belongs_to :form  # Strictly speaking this is redundant, but SQL can't handle arbitrary nesting

  validates_presence_of :form_line
  validates_presence_of :form

  before_create :detect_form_from_parent

  class << self
    # Define properties that are known to this class.  These extend the
    # properties known by the parent class.
    #
    # Only known properties are accepted.
    def has_properties(props)
      self.direct_properties.merge!(props)
    end

    # Only this Item's properties.  Use Item#properties to see the properties of all its
    # superclasses as well.
    def direct_properties
      @properties ||= {}
    end

    # Returns all properties known by this Item.  This includes the properties
    # of all its superclasses.  Use Item#direct_properties if you only want to know
    # this particular Item's properties.
    def properties
      (self.superclass.respond_to?(:properties) ? self.superclass.properties : {}).merge(self.direct_properties)
    end

    # Get the description string for a property.
    def get_property_description(name)
      self.properties[name.to_sym][0]
    end

    def concrete_item?; false; end

    # Get the cell class that belongs to this item.
    def cell_class
      (self.name + "Cell").constantize
    end

    # Human-readable description of the item.  Defaults to a humanized version of the class name.
    def item_name
      self.name.underscore.humanize
    end
  end

  # All form items can be conditionally shown
  has_properties :conditional => ["Show if", ""]

  def parse_conditional_property_value(value)
    CQL::parse(value)
  end

  # Obtain an Array of form items that this item directly depends upon
  def dependencies(form)
    unless @dependencies
      vars = CQL.used_variables(self.get_property_value(:conditional))
      items_belonging_to_vars = vars.map {|v| form.get_var_item v }
      items_belonging_to_vars.compact!
      @dependencies = items_belonging_to_vars
    end
    @dependencies
  end

  # Obtain an Array of form items that directly depend upon this item
  def dependees(form)
    unless @dependees
      if self.variable_name.empty?
        @dependees = []
      else
        @dependees = form.form_items.find_all{|i| i.dependencies(form).include?(self) }
      end
    end
    @dependees
  end

  # Store the given properties for the item if possible.
  # props is supposed to be a hash of :property_name => "value"
  def store_properties(props)
    props.each_pair do |name, value|
      if value.is_a?(StringIO) || value.is_a?(Tempfile)
        value.rewind
        value = value.read
      end
      prop = self.get_property(name.to_s)
      if value.blank?
#        prop.destroy if prop
        self.form_item_properties.delete(prop) if prop
      else
        if prop
          prop.value = value
        else
          prop = FormItemProperty.new(:name => name.to_s, :value => value, :form_item => self)
          self.form_item_properties << prop
        end
        prop.save
      end
    end
  end

  # Simple check if the item is selected by the user.  To be set to true in a controller
  # if the item is supposed to be selected
  attr_accessor :selected

  def initialize(*args)
    raise(TypeError, "#{self.class.name} cannot be instantiated!") unless self.class.concrete_item?
    super(*args)
  end

  # Get the property given by the name, if it's available.  nil otherwise
  def get_property(name)
    self.form_item_properties.detect {|p| p.name.to_s == name.to_s }
  end

  # Get the (parsed) property value of the property given by name, or the
  # default if there is no value.
  def get_property_value(name)
    prop = self.get_property(name)
    begin
      return prop.parsed_value(self) if prop
    rescue TypeError
    end
    # Sucks to do this, but we have to construct a new instance to be able to do this cleanly.
    @defaults ||= {}
    @defaults[name] ||= FormItemProperty.new(:value => get_property_default(name), :form_item => self, :name => name).parsed_value(self)
  end

  # Get the default (unparsed) string value for a property.
  def get_property_default(name)
    d = self.class.properties[name.to_sym][1]
    if d.is_a?(Proc)
      self.instance_eval &d
    else
      d
    end
  end

  # All items have a different type of value they store.  But in the database we
  # only have a string, so we need to convert this manually to the right type of
  # value.  Hence the parse_value method.
  #
  # This method is expected to throw a TypeError if it cannot parse the value.
  # The default FormItem#parse_value simply returns the input.
  def parse_value(value)
    value
  end

  # Properties also have a 'type' of some sort associated with them.
  # This validates the type of the property and any optional additional
  # things that the Item wants to check.
  #
  # Properties can't do their own validation because the way they are used
  # depends very much on the item they're associated with.
  #
  # The default Item#validate_property sends parse_(property.name)_value
  # to self, if it is there.  This will handle parsing of the property,
  # with semantics similar to Item#parse_value. (ie, it either returns the
  # value or it will raise a TypeError)
  def validate_property(property)
    begin
      # XXX TODO implement some kind of check against OTHER property
      # values as well.  (example; maximum cannot be less than minimum)
      # Nothing is done besides parse and check for error yet
      property.parsed_value(self)
    rescue TypeError => e
      property.errors.add(:value, e.message)
    end
  end

  # Let this FormItem check if the FormItemValue the user has filled in matches
  # its constraints and if the value is can be parsed.
  def validate_item_value(item_value)
    begin
      item_value.parsed_value(self)  # Trigger parser
      self.validate_constraints(item_value).each {|err| item_value.errors.add(:value, err) }
    rescue TypeError => e
      item_value.errors.add(:value, e.message)
    end
  end

  # Given a value, validate all constraints on this FormItem.  Returns an Array
  # of error messages.  This Array is empty if there are no errors.
  #
  # It tries to send validate_(property.name)_value to self, if it is there.
  # Its first argument is the FormItemValue, its second is a FormItemProperty.
  def validate_constraints(item_value)
    self.form_item_properties.inject([]) do |errors, prop|
      if self.respond_to?("validate_#{prop.name}_value")
        err = self.send("validate_#{prop.name}_value", item_value, prop)
        errors << err if err
      end
      errors
    end
  end

  # Parse integer value.
  #
  # An integer is an optional sign followed by a number of digits followed by an
  # optional exponent followed by an optional sign followed by a number of digits.
  #
  # Examples:
  # 100
  # -2
  # +2
  # 100e2
  # +2e-1
  def parse_integer_value(value)
    if !value.match(/^[[:space:]]*[+-]?[0-9]+([eE][+-]?[0-9]+)?[[:space:]]*$/)
      raise TypeError, "This must be an integer."
    else
      # We're using to_f here so we can support scientific notation.  to_i doesn't
      # accept this, it just truncates after seeing something other than a number.
      value.to_f.to_i
    end
  end

  # Parse float value.
  #
  # A float is an optional sign followed by _either_ a number of digits followed by an
  # optional dot _or_ zero or more digits followed by a dot followed by a number of
  # digits.  After this, we get an optional exponent followed by an optional sign
  # followed by a number of digits.
  #
  # Examples:
  # 100
  # -2
  # +2
  # 100e2
  # +2e-1
  def parse_float_value(value)
    if !value.match(/^[[:space:]]*[+-]?([0-9]+\.?|[0-9]*\.[0-9]+)([eE][+-]?[0-9]+)?[[:space:]]*$/)
      raise TypeError, "This must be a floating-point number."
    else
      value.to_f
    end
  end

protected
  def detect_form_from_parent
    parent = self.form_line
    parent = parent.line_group until parent.is_a?(Form)
    self.form = parent
  end
end
