# An email control is simply a field type for email addresses.
class EmailControl < TextControl
  def parse_value(value)
    # See RFC822 for the _real_ spec, but that's pretty elaborate and most likely
    # mailservers don't accept, say, quoted strings with control characters anyway.
    raise TypeError, "This is not a valid e-mail address" unless value.match(/^[a-z0-9\-_][a-z0-9\-_.]*@[a-z0-9\-_]+\.[a-z0-9\-_.]+$/)
    value
  end
end
