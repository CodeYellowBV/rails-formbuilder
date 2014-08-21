require 'test_helper'

class FormResponseTest < ActiveSupport::TestCase
  fixtures :forms, :form_items, :form_lines

  def test_presence_of_form
    resp = FormResponse.new
    assert !resp.save
    assert resp.errors[:form].any?
    resp.form = forms(:personal_info_form)
    assert resp.save
  end

  def test_item_value
    resp = FormResponse.create!(:form => forms(:personal_info_form))
    i = FormItemValue.create!(:form_item => form_items(:name), :value => "jack", :form_response => resp)
    form_items(:address).store_properties(:default_value => "default-address")
    resp.reload

    assert_equal "default-address", resp.item_value(form_items(:address))
    assert_equal "default-address", resp.item_value(form_items(:address).id)
    assert_equal "jack", resp.item_value(form_items(:name))
    assert_equal "jack", resp.item_value(form_items(:name).id)

    i = FormItemValue.new(:form_item => form_items(:address), :value => "Whitechapel", :form_response => resp)
    resp.form_item_values << i
    assert_equal "Whitechapel", resp.item_value(form_items(:address))
    # Invalid fields should not return the default but nil
    i.value = ""
    assert_nil resp.item_value(form_items(:address))

    i = FormItemValue.new(:form_item => form_items(:street_number), :form_response => resp, :value => "1")
    assert_equal 1, i.parsed_value(form_items(:street_number))
    i.save!
    resp.reload
    assert_equal 1, resp.item_value(form_items(:street_number))
    assert_equal 1, resp.item_value(form_items(:street_number).id)
  end

  def test_var_value
    resp = FormResponse.create!(:form => forms(:personal_info_form))
    name = form_items(:name)
    FormItemValue.create!(:form_item => name, :value => "jack", :form_response => resp)
    resp.reload

    assert_nil resp.var_value(:name)

    name.variable_name = "name"
    name.save!
    resp.reload
    assert_equal "jack", resp.var_value(:name)
  end

  def test_form_var_values
    resp = FormResponse.create!(:form => forms(:personal_info_form))
    name = form_items(:name)
    FormItemValue.create!(:form_item => name, :value => "jack", :form_response => resp)
    street_number = form_items(:street_number)
    FormItemValue.create!(:form_item => street_number, :value => "42", :form_response => resp)
    resp.reload

    assert_equal({}, resp.form_var_values)

    name.variable_name = "name"
    name.save!
    street_number.variable_name = "street"
    street_number.save!
    resp.reload

    assert_equal({:name => "jack", :street => 42}, resp.form_var_values)
  end

  def test_visible?
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)
    a = IntegerControl.create!(:variable_name => "a", :form => form, :form_line => line)
    b = IntegerControl.create!(:variable_name => "b", :form => form, :form_line => line)
    c = IntegerControl.create!(:variable_name => "c", :form => form, :form_line => line)
    b.store_properties(:conditional => "a > 10", :max => "50")
    c.store_properties(:conditional => "a > 8 and b > 1")
    d = IntegerControl.create!(:variable_name => "d", :form => form, :form_line => line)
    d.store_properties(:conditional => "nonexistant > 10")

    resp = FormResponse.create!(:form => form)
    
    assert resp.visible?(a)
    assert !resp.visible?(b)
    assert !resp.visible?(c)
    assert !resp.visible?(d)

    aval = FormItemValue.create!(:form_response => resp, :form_item => a, :value => "1")
    resp.reload
    b.reload

    assert !resp.visible?(b)

    aval.value = "11"
    aval.save!
    resp.reload
    a.reload
    b.reload
    assert resp.visible?(b)
    assert !resp.visible?(c)

    bval = FormItemValue.create!(:form_response => resp, :form_item => b, :value => "1")
    resp.reload
    assert !resp.visible?(c)

    bval.value = "2"
    bval.save!
    resp.reload
    c.reload
    assert resp.visible?(c)

    # Both a and b have acceptable values for c to be shown,
    # but b is not shown (nil), so c shouldn't be shown either:
    aval.value="9"
    aval.save!
    resp.reload
    b.reload
    c.reload
    assert !resp.visible?(b)
    assert !resp.visible?(c)
  end

  def test_default_visible?
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)
    a = IntegerControl.create!(:variable_name => "a", :form => form, :form_line => line)
    a.store_properties(:default_value => "5")
    b = IntegerControl.create!(:variable_name => "b", :form => form, :form_line => line)
    b.store_properties(:conditional => "a > 2")

    resp = FormResponse.create!(:form => form)
    assert resp.visible?(a)
    assert resp.visible?(b)
  end

  def test_invalid_visible?
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)
    a = IntegerControl.create!(:variable_name => "a", :form => form, :form_line => line)
    b = IntegerControl.create!(:variable_name => "b", :form => form, :form_line => line)
    a.store_properties(:max => "5")
    b.store_properties(:conditional => "a > 10")

    resp = FormResponse.create!(:form => form)
    assert resp.visible?(a)
    assert !resp.visible?(b)

    aval = FormItemValue.new(:form_response => resp, :form_item => a, :value => "11")
    resp.form_item_values << aval
    assert resp.visible?(a)
    assert !resp.visible?(b)
  end

  def test_cyclic_visible?
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)
    a = IntegerControl.create!(:variable_name => "a", :form => form, :form_line => line)
    b = IntegerControl.create!(:variable_name => "b", :form => form, :form_line => line)
    a.store_properties(:conditional => "b > 8")
    b.store_properties(:conditional => "a > 10")

    resp = FormResponse.create!(:form => form)
    assert !resp.visible?(a)
    assert !resp.visible?(b)

    # Even setting values should not cause these to be visible
    aval = FormItemValue.create!(:form_response => resp, :form_item => a, :value => "10")
    bval = FormItemValue.create!(:form_response => resp, :form_item => b, :value => "20")
    resp.reload
    a.reload
    b.reload
    assert !resp.visible?(a)
    assert !resp.visible?(b)
  end
end
