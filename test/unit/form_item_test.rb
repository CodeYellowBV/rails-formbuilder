require File.dirname(__FILE__) + '/../test_helper'

# Ruby does not allow me to define classes inside methods, so they are defined here
class Foo < FormItem
  has_properties :conditional => false, :qux => "blah", :mooh => "a cow says"

  def validate_mooh_value(item_value, property)
    "Sorry, foo is always invalid!"
  end

  def validate_qux_value(item_value, property)
    item_value.parsed_value(self) == property.parsed_value(self) ? "Unacceptable value" : false
  end

  def self.concrete_item?; true; end
end

class Bar < Foo
  has_properties :frobnitz => "narf", :mooh => "milk++"

  def validate_mooh_value(item_value, property)
    item_value.parsed_value(self).empty? ? "value should not be empty!" : false
  end
end

class NonConcrete < FormItem
end

class Concrete < NonConcrete
  def self.concrete_item?; true; end
end

class ConcreteSub < Concrete
end

class Qux < ActiveRecord::Base
end

class FormItemTest < ActiveSupport::TestCase
  def test_properties
    assert_equal({:conditional => false, :mooh => "a cow says", :qux => "blah"}, Foo.properties)

    assert_equal({:conditional => false, :frobnitz => "narf", :mooh => "milk++", :qux => "blah"}, Bar.properties)
  end

  def test_validate_constraints
    foo = Foo.new
    fiv = FormItemValue.new(:form_item => foo)

    fiv.value = "blahblahblah"
    assert_equal [], foo.validate_item_value(fiv)
    fiv.value = "blahblahblah"
    assert_equal [], foo.validate_item_value(fiv)
    fiv.value = "qux sucks"
    assert_equal [], foo.validate_item_value(fiv)

    foo.form_item_properties << FormItemProperty.new(:name => "mooh", :value => "irrelevant")
    fiv.value = "blahblahblah"
    assert_equal ["Sorry, foo is always invalid!"], foo.validate_constraints(fiv)
    fiv.value = ""
    assert_equal ["Sorry, foo is always invalid!"], foo.validate_constraints(fiv)
    fiv.value = "qux sucks"
    assert_equal ["Sorry, foo is always invalid!"], foo.validate_constraints(fiv)

    foo.form_item_properties << FormItemProperty.new(:name => "qux", :value => "xyz")
    fiv.value = "blahblahblah"
    assert_equal ["Sorry, foo is always invalid!"], foo.validate_constraints(fiv)
    fiv.value = ""
    assert_equal ["Sorry, foo is always invalid!"], foo.validate_constraints(fiv)
    fiv.value = "xyz"
    assert_equal ["Sorry, foo is always invalid!", "Unacceptable value"], foo.validate_constraints(fiv).sort

    # Test 'inheritance' of properties
    bar = Bar.new
    fiv.value = "blahblahblah"
    assert_equal [], bar.validate_constraints(fiv)
    fiv.value = ""
    assert_equal [], bar.validate_constraints(fiv)
    fiv.value = "qux sucks"
    assert_equal [], bar.validate_constraints(fiv)

    bar.form_item_properties << FormItemProperty.new(:name => "qux", :value => "qux sucks")
    fiv.value = "blahblahblah"
    assert_equal [], bar.validate_constraints(fiv)
    fiv.value = ""
    assert_equal [], bar.validate_constraints(fiv)
    fiv.value = "qux sucks"
    assert_equal ["Unacceptable value"], bar.validate_constraints(fiv)

    bar.form_item_properties << FormItemProperty.new(:name => "mooh")
    fiv.value = "blahblahblah"
    assert_equal [], bar.validate_constraints(fiv)
    fiv.value = ""
    assert_equal ["value should not be empty!"], bar.validate_constraints(fiv)
    fiv.value = "qux sucks"
    assert_equal ["Unacceptable value"], bar.validate_constraints(fiv)
  end

  def test_concreteness
    assert_raises(TypeError){ FormItem.new }
    assert_raises(TypeError){ NonConcrete.new }
    assert_nothing_raised { Concrete.new }
    assert_nothing_raised { ConcreteSub.new }
  end

  def test_parse_integer
    fi = Concrete.new
    assert_raises(TypeError) { fi.parse_integer_value("") }
    assert_raises(TypeError) { fi.parse_integer_value("a") }
    assert_raises(TypeError) { fi.parse_integer_value("0a") }
    assert_raises(TypeError) { fi.parse_integer_value("a1") }

    assert_raises(TypeError) { fi.parse_integer_value("0.1") }
    assert_raises(TypeError) { fi.parse_integer_value(".1") }

    assert_equal 300000, fi.parse_integer_value("3e5")
    assert_raises (TypeError) { fi.parse_integer_value("0.3e6") }
    assert_equal 0, fi.parse_integer_value("3e-6")
    assert_raises (TypeError) { fi.parse_integer_value("0.3e-5") }

    assert_equal 1, fi.parse_integer_value("1")
    assert_kind_of Integer, fi.parse_integer_value("1")
    assert_equal 1, fi.parse_integer_value("0001")
    assert_kind_of Integer, fi.parse_integer_value("0001")
    assert_equal 1, fi.parse_integer_value("  1 ")
    assert_kind_of Integer, fi.parse_integer_value("  1 ")
  end

  def test_parse_float
    fi = Concrete.new
    assert_raises(TypeError) { fi.parse_float_value("") }
    assert_raises(TypeError) { fi.parse_float_value("a") }
    assert_raises(TypeError) { fi.parse_float_value("0a") }
    assert_raises(TypeError) { fi.parse_float_value("a1") }

    assert_equal 1, fi.parse_float_value("1")
#    assert_kind_of Float, fi.parse_integer_value("1")  # to_f does NOT always return Floats
    assert_equal 1, fi.parse_float_value("0001")
#    assert_kind_of Float, fi.parse_float_value("0001")
    assert_equal 1, fi.parse_float_value("  1 ")
#    assert_kind_of Float, fi.parse_float_value("1")
    assert_equal 0.1, fi.parse_float_value("0.1")
    assert_kind_of Float, fi.parse_float_value("0.1")
    assert_equal 0.1, fi.parse_float_value(" 0.1 ")
    assert_kind_of Float, fi.parse_float_value(" 0.1 ")

    assert_equal 300000, fi.parse_float_value("3e5")
    assert_equal 300000, fi.parse_float_value("0.3e6")
    assert_equal 0.000003, fi.parse_float_value("3e-6")
    assert_equal 0.000003, fi.parse_float_value("0.3e-5")
  end

  fixtures :forms, :form_lines

  def test_dependencies
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)
    a = IntegerControl.create!(:variable_name => "a", :form => form, :form_line => line)
    b = IntegerControl.create!(:variable_name => "b", :form => form, :form_line => line)
    b.store_properties(:conditional => "a > 10")
    
    form.reload
    assert_equal([a], b.dependencies(form))

    c = IntegerControl.create!(:variable_name => "c", :form => form, :form_line => line)
    b.store_properties(:conditional => "a > 10 AND c < 1")
    # FormItems cache their stuff
    b = FormItem.find(b.id)
    form.reload
    assert_equal([a, c], b.dependencies(form))
    
    # Nonexistant items
    b.store_properties(:conditional => "a > 10 AND c < 1 AND d > 1")
    form.reload

    # FormItems cache their stuff
    a = FormItem.find(a.id)
    b = FormItem.find(b.id)
    c = FormItem.find(c.id)
    assert_equal([a, c], b.dependencies(form))
  end

  def test_dependees
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)
    a = IntegerControl.create!(:variable_name => "a", :form => form, :form_line => line)
    b = IntegerControl.create!(:variable_name => "b", :form => form, :form_line => line)
    b.store_properties(:conditional => "a > 10")

    a.reload
    form.reload
    assert_equal([b], a.dependees(form))

    c = IntegerControl.create!(:variable_name => "c", :form => form, :form_line => line)
    c.store_properties(:conditional => "a > 10 AND b < 1")
    # FormItems cache their stuff
    a = FormItem.find(a.id)
    b = FormItem.find(b.id)
    form.reload
    assert_equal([b, c], a.dependees(form))
  end

  def test_auto_variable_name_assignment
    form = forms(:empty_form)
    line = FormLine.new(:line_group => form)
    line.save!
    a = IntegerControl.new(:form_line => line, :form => form)
    a.save!

    assert_equal("variable1", a.variable_name)

    b = TextControl.new(:form_line => line, :form => form)
    b.save!

    assert_equal("variable2", b.variable_name)

    a.destroy
    b.destroy

    c = TextAreaControl.new(:form_line => line, :form => form)
    c.save!

    assert_equal("variable1", c.variable_name)

    c.variable_name = "testvar"
    c.save!

    d = CheckboxControl.new(:form_line => line, :form => form)
    d.save!
    assert_equal("variable1", d.variable_name)

    c.destroy
    e = SelectControl.new(:form_line => line, :form => form)
    e.save!
    assert_equal("variable2", e.variable_name)

    d.destroy
    e.variable_name = 'variablewtf'
    e.save!
    
    f = IntegerControl.new(:form_line => line, :form => form)
    f.save!
    assert_equal("var_id_#{e.id + 1}", f.variable_name)
  end
end
