# A FormItemProperty is a name/value pair for a particular form item.
# Every form item knows what name/values it accepts and understands.
# Some properties are interpreted as constraints and some as simple
# styling properties.
class FormItemProperty < ActiveRecord::Base
  belongs_to :form_item

  validates_presence_of :form_item
  validates_presence_of :name
  validates_presence_of :value

  validate :validate_form_item_property

  before_save :marshal
  after_save :unmarshal
  after_find :unmarshal

  def initialize(*args)
    super(*args)
    self.value = self.form_item.get_property_default(self.name) if self.name and (self.value.nil? || self.value == "") and self.form_item and self.form_item.get_property(self.name)
  end

  # The FormItem is supposed to check this object's value and other things and add errors to this object.
  # This is a little weird, but the easiest way to handle the big variety of form types without subclassing
  # FormItemProperty.  We're not in Java here! :)
  def validate_form_item_property
    if self.form_item
      if self.form_item.class.properties[self.name.to_sym]
        self.form_item.validate_property(self)
      else
        self.errors.add(:name, "Unknown property name")
      end
    end
  end

  # Setting the form item clears the cached parsed value.
  def form_item_id=(value)
    clear_parsed_value
    super(value)
  end

  # Setting the value clears the cached parsed value.
  def value=(value)
    clear_parsed_value
    super(value)
  end

  # This returns the parsed value.  If it isn't available yet,
  # it will be parsed.  This invokes
  # FormItem#parse_(property.name)_property_value, if it is available.
  # This is expected to return either a value or raise a TypeError.
  # If none exists, the value is returned as-is.
  #
  # Parsing is only done the first time.  After that, it will return
  # a memoized value.  The memoized value is cleared when either the
  # form item is changed or the value is changed.
  # This can also be explicitly cleared by calling clear_parsed_value.
  #
  # It is an error to call this method on a FormItemProperty with no form_item
  def parsed_value(form_item)
    if form_item.respond_to?("parse_#{self.name}_property_value")
      @parsed_value ||= form_item.send("parse_#{self.name}_property_value", self.value)
    else
      self.value
    end
  end

  # Clear the parsed_value cache.
  def clear_parsed_value
    @parsed_value = nil
  end
  
protected
  # After finding a record, unmarshal the value to the correct type.
  def unmarshal
    self.value = YAML::load(self.value) if self.value != nil
  end

  # Before saving, we need to Marshal the value to fit it into the
  # database string field, because the value can be either a string or an
  # array (in case of checkboxes, for example).
  # If it is a string, we might need to do some encoding to the right type.
  # Doing it here instead of at value=, we can have our validation check
  # if it can be translated at all.
  def marshal
    self.value = YAML::dump(self.value) if self.value != nil
  end
end
