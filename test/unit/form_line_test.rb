require File.dirname(__FILE__) + '/../test_helper'

class FormLineTest < ActiveSupport::TestCase
  fixtures :forms, :form_lines, :form_items

  def test_ordering
    line = form_lines(:personal_line2)
    assert_equal [form_items(:address).id, form_items(:street_number).id], line.form_items.map{|i| i.id}

    form_items(:address).update_attributes(:offset => 100)
    line.reload
    assert_equal [form_items(:street_number).id, form_items(:address).id], line.form_items.map{|i| i.id}
  end
end
