require 'test_helper'

class FormTest < ActiveSupport::TestCase
  fixtures :forms, :form_items, :form_lines

  def test_get_var_item
    form = Form.new()
    a = IntegerControl.new(:variable_name => "a")
    form.form_items << a
    b = IntegerControl.new(:variable_name => "b")
    form.form_items << b

    assert_equal(a, form.get_var_item(:a))
    assert_equal(a, form.get_var_item("a"))
    assert_equal(b, form.get_var_item(:b))
    assert_nil(form.get_var_item(:c))
  end

  def test_destroy
    forms(:personal_info_form).destroy
  end
end
