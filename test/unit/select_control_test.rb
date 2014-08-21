require 'test_helper'

class SelectControlTest < ActiveSupport::TestCase
  fixtures :forms, :form_lines

  def test_empty
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)

    sc = SelectControl.new(:form => form, :form_line => line)
    assert_nothing_raised { sc.store_properties(:options => '') }
  end

  def test_invalid_options
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)

    sc = SelectControl.new(:form => form, :form_line => line)
    sc.save
    sc.store_properties(:options => "one\ntwo")
    sc.save
    assert_raises(TypeError) do
      sc.get_property(:options).parsed_value(sc)
    end
    sc.reload
    assert_nil sc.get_property(:options)
  end

  def test_flat_options
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)

    sc = SelectControl.new(:form => form, :form_line => line)
    assert_nothing_raised do
      sc.store_properties(:options => "# one\r\n# The second option:two")
      sc.get_property(:options).parsed_value(sc)
    end
    assert_equal 'one', sc.option_name_for_value('1')
    assert_equal 'The second option', sc.option_name_for_value('two')
  end

  def test_default_options
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)

    sc = SelectControl.new(:form => form, :form_line => line)
    assert_nothing_raised do
      sc.store_properties(:options => "# one\r\n* The second option:two")
      sc.get_property(:options).parsed_value(sc)
    end
    assert_equal ['two'], sc.default_value
  end

  def test_grouped_options
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)

    sc = SelectControl.new(:form => form, :form_line => line)
    assert_nothing_raised do
      sc.store_properties(:options => "og. options\r\n## one\r\n## The second option:two")
      sc.get_property(:options).parsed_value(sc)
    end
    assert_equal 'one', sc.option_name_for_value('1')
    assert_equal 'The second option', sc.option_name_for_value('two')
  end

end
