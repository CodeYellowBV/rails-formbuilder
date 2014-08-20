require File.dirname(__FILE__) + '/../test_helper'

# Need to have this here or activerecord will complain... sigh!
class PINNumberTest < FormItem
  def self.concrete_item?; true; end

  has_properties :not_too_simple => "Should not be too simple", :disallowed_digit => "This digit is not allowed"

  def parse_value(value)
    if !value.match(/[0-9]{4}/)
      raise TypeError, "A PIN Number must be a number of exactly 4 digits"
    end
    value.to_i
  end

  def validate_not_too_simple_value(item_value, property)
    if !item_value.parsed_value(self).is_a? Integer
      raise RuntimeError, "Unparsed value.  Cannot be tested, afaik, so we just raise a runtime error instead..."
    elsif item_value.parsed_value(self).to_s == property.parsed_value(self)
      "Value is too simple"
    else
      false
    end
  end

  def validate_disallowed_digit_value(item_value, property)
    if !item_value.parsed_value(self).is_a? Integer
      raise RuntimeError, "Unparsed value.  Cannot be tested, afaik, so we just raise a runtime error instead..."
    elsif item_value.parsed_value(self).to_s.include?(property.value)
      "#{property.value} is not an allowed digit"
    else
      false
    end
  end
end

class FormItemValueTest < ActiveSupport::TestCase
  fixtures :forms, :form_lines, :form_items, :form_responses, :form_item_values

#  Deactivated due to performance problem with this check.
#  It should never happen in the application anyway.... :/
#  At least the database will catch this with a "duplicate value" exception
#  def test_uniqueness
#    value = FormItemValue.new(:form_response => form_responses(:empty_response), :form_item => form_items(:name), :value => "John Doe")
#    assert value.save
#
#    value = FormItemValue.new(:form_response => form_responses(:empty_response), :form_item => form_items(:name), :value => "Mooh")
#    assert !value.save
#    assert value.errors[:form_item_id].any?
#    value.form_item = form_items(:address)
#    assert value.save
#  end

  def test_presence
    value = FormItemValue.new(:value => "foo")
    assert !value.save
    assert value.errors[:form_response].any?
    assert value.errors[:form_item].any?

    value.form_response = form_responses(:empty_response)
    assert !value.save
    assert !value.errors[:form_response].any?
    assert value.errors[:form_item].any?

    value.form_item = form_items(:name)
    assert value.save
  end

  def test_validate
    pn = PINNumberTest.new(:form_line => form_lines(:personal_line1), :form => form_lines(:personal_line1).line_group)
    assert pn.save

    pinvalue = FormItemValue.new(:form_item => pn, :value => "abc", :form_response => form_responses(:empty_response))
    assert_nothing_raised { pinvalue.save }
    assert !pinvalue.save
    assert pinvalue.errors[:value].any?
    assert_equal ["A PIN Number must be a number of exactly 4 digits"], pinvalue.errors[:value]

    pinvalue.value = "1111"
    assert_nothing_raised { pinvalue.save }
    assert pinvalue.save

    pn.form_item_properties << FormItemProperty.new(:name => "not_too_simple", :value => "1111")
    assert !pinvalue.save
    assert_equal ["Value is too simple"], pinvalue.errors[:value]

    pinvalue.value = "2222"
    assert pinvalue.save

    pn.form_item_properties << FormItemProperty.new(:name => "not_too_simple", :value => "2222")
    assert !pinvalue.save
    assert_equal ["Value is too simple"], pinvalue.errors[:value]

    pinvalue.value = "1111"  # check if this still is checked, now we have two too simple values
    assert !pinvalue.save
    assert_equal ["Value is too simple"], pinvalue.errors[:value]

    # Test validation failure of multiple instances of the same property
    pn.form_item_properties << FormItemProperty.new(:name => "not_too_simple", :value => "1111")
    assert !pinvalue.save
    assert_equal ["Value is too simple", "Value is too simple"], pinvalue.errors[:value]

    # Test validation failure of one of two properties
    pn.form_item_properties << FormItemProperty.new(:name => "disallowed_digit", :value => "3")
    pinvalue.value = "3333"
    assert !pinvalue.save
    assert_equal ["3 is not an allowed digit"], pinvalue.errors[:value]

    # Test validation failure of two properties
    pn.form_item_properties << FormItemProperty.new(:name => "disallowed_digit", :value => "2")
    pinvalue.value = "2222"
    assert !pinvalue.save
    assert_equal ["2 is not an allowed digit", "Value is too simple"], pinvalue.errors[:value].sort

    pinvalue.value = "4567"
    assert pinvalue.save
  end

  def test_parsed_value
    pn = PINNumberTest.new(:form_line => form_lines(:personal_line1), :form => form_lines(:personal_line1).line_group)
    assert pn.save

    pinvalue = FormItemValue.new(:form_item => pn, :value => "1111", :form_response => form_responses(:empty_response))
    assert pinvalue.save

    assert_equal 1111, pinvalue.parsed_value(pn)

    pn2 = PINNumberTest.new(:form_line => form_lines(:personal_line1), :form => form_lines(:personal_line1).line_group)
    assert pn2.save
    pinvalue = FormItemValue.create!(:form_item => pn2, :value => "1234", :form_response => form_responses(:empty_response))
    assert_equal 1234, pinvalue.parsed_value(pn)
    pinvalue.reload
    assert_equal 1234, pinvalue.parsed_value(pn)
  end
end
