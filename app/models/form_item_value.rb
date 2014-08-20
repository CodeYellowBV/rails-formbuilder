# A FormItemValue is a value that was filled in for the variable defined
# by a FormItem.  It is filled in as part of a FormResponse.
# Currently only FormControl items can define a variable.
#
# Values can either be strings or Arrays of strings, depending on the type
# of control.  Selectionlists and things where one control manages several
# values have Array values, others have just Strings.
#
# The parser methods for values have to know about the expected type for a
# value.
class FormItemValue < ActiveRecord::Base
  belongs_to :form_response
  belongs_to :form_item

  # This kills performance and should never happen, so we comment it out
#  validates_uniqueness_of :form_item_id, :scope => :form_response_id, :message => "can only be provided with a value once!"
  validates_presence_of :form_item
  validates_presence_of :form_response

  validate :validate_form_item_value

  before_save :marshal
  after_save :unmarshal
  after_find :unmarshal

  # The FormItem is supposed to check its constraints and add errors to this object.  This is a little
  # weird, but the easiest way to handle the big variety of form types without subclassing FormItemValue.
  # We're not in Java here! :)
  def validate_form_item_value
    self.form_item.validate_item_value(self) if self.form_item
    # The "if" here is so complex for performance reasons...
    errors.add(:form, "must be the same as the response's form") if self.form_item && self.form_response && (self.form_item.form_id || self.form_item.form.id) != (self.form_response.form_id || self.form_response.form.id)
    # Poor man's validates_presence_of (we can't use the real one because empty lists and false are also considered "blank"
    errors.add(:value, "can't be blank") if self.value.nil? || self.value == ""
  end

  # Setting the form item clears the cached parsed value.
  def form_item_id=(value)
    clear_parsed_value
    super(value)
  end

  # Setting the value clears the cached parsed value.
  def value=(value)
    clear_parsed_value
    if value.respond_to?(:rewind) # Several different classes of file upload support this
      begin
        value.rewind
        value = value.read
        # There's a weird "uninitialized stream" error that you get when
        # the browser sends no proper data. (try refreshing and reposting
        # the form, or some such)
      rescue IOError
        value = nil
      end
    end
    super(value)
  end

  # This returns the parsed value.  If it isn't available yet,
  # it will be parsed.  This invokes FormItem#parse_value, meaning
  # it returns either a value or raises a TypeError.
  #
  # Parsing is only done the first time.  After that, it will return
  # a memoized value.  The memoized value is cleared when either the
  # form item is changed or the value is changed.
  # This can also be explicitly cleared by calling clear_parsed_value.
  #
  # It is an error to call this method on a FormItemValue with no form_item
  def parsed_value(form_item)
    @parsed_value ||= form_item.parse_value(self.value)
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
