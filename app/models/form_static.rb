# FormStatic is simply a static description or image that has no active
# role in a form.  These are intended to guide or amuse the reader.
class FormStatic < FormItem
  has_properties :contents => ["Text contents", "Type your text here"]
end
