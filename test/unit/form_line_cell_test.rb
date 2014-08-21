require 'test_helper'

require 'rexml/document'

class FormLineTest < ActiveSupport::TestCase
  def test_xml_export
    l = FormLine.new()

    content = element_cell_state(l, :xml_export)
    assert_equal([], REXML::Document.new(content).root.get_elements('*'))

    l.form_items << IntegerControl.new(:offset => 1.2, :variable_name => "hai")
    content = REXML::Document.new(element_cell_state(l, :xml_export)).root
    attribs = {}
    content.get_elements('item')[0].attributes.each {|a, b| attribs[a] = b }
    assert_equal({"type" => "integer_control", "variable_name" => "hai", "offset" => "1.2"}, attribs)

    l.form_items << TextControl.new(:offset => 2.0, :variable_name => "hello")
    content = REXML::Document.new(element_cell_state(l, :xml_export)).root
    attribs = {}
    content.get_elements('item')[0].attributes.each {|a, b| attribs[a] = b }
    assert_equal({"type" => "integer_control", "variable_name" => "hai", "offset" => "1.2"}, attribs)
    attribs = {}
    content.get_elements('item')[1].attributes.each {|a, b| attribs[a] = b }
    assert_equal({"type" => "text_control", "variable_name" => "hello", "offset" => "2.0"}, attribs)
  end


  def test_xml_import
    d = REXML::Document.new(<<'EOF').root
<line>
  <item type="text_control" />
  <item type="integer_control" />
</line>
EOF
    l = FormLine.new
    element_cell_state(l, :xml_import, :xml => d)

    assert_equal 2, l.form_items.length
    assert_instance_of TextControl, l.form_items[0]
    assert_instance_of IntegerControl, l.form_items[1]
  end


end
