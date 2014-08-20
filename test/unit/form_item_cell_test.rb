require File.dirname(__FILE__) + '/../test_helper'

require 'rexml/document'

class FormItemCellTest < ActiveSupport::TestCase
  def test_xml_export
    i = TextControl.new(:offset => 4.5, :variable_name => "testing")

    content = REXML::Document.new(element_cell_state(i, :xml_export)).root
    attribs = {}
    content.attributes.each {|a, b| attribs[a] = b }
    assert_equal({"type" => "text_control", "variable_name" => "testing", "offset" => "4.5"}, attribs)

    i.store_properties(:default => "Salt & Vinegar")
    content = REXML::Document.new(element_cell_state(i, :xml_export)).root
    attribs = {}
    content.attributes.each {|a, b| attribs[a] = b }
    assert_equal({"type" => "text_control", "variable_name" => "testing", "offset" => "4.5"}, attribs)

    prop = content.get_elements('property')[0]
    attribs = {}
    prop.attributes.each {|a, b| attribs[a] = b }
    assert_equal({"name" => "default"}, attribs)
    assert_equal("Salt & Vinegar", prop.get_text.value)
  end

  def test_xml_import
    d = REXML::Document.new(<<'EOF').root
<item type="text_control" offset="1.234" variable_name="testvar">
  <property name="display_length">123</property>
  <property name="default_value">hello, there</property>
</item>
EOF
    i = TextControl.new
    element_cell_state(i, :xml_import, :xml => d)

    assert_equal "testvar", i.variable_name
    assert_equal 2, i.form_item_properties.length
    assert_equal 123, i.get_property_value(:display_length)
    assert_equal "hello, there", i.get_property_value(:default_value)
  end
end
