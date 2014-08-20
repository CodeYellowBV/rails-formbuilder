require File.dirname(__FILE__) + '/../test_helper'

require 'rexml/document'

class FormCellTest < ActiveSupport::TestCase
  def test_xml_export
    f = Form.new(:name => "fooform")
    f.ruler_positions = [1.1, 1.2, 3.1234]

    content = REXML::Document.new(element_cell_state(f, :xml_export)).root
    attribs = {}
    content.attributes.each {|a, b| attribs[a] = b }
    assert_equal({"name" => "fooform"}, attribs)
    pos = content.get_elements('rulerpos/pos').to_a.map(&:get_text).map(&:value)
    assert_equal(["1.1", "1.2", "3.1234"], pos)

    f.form_lines << FormLine.new
    content = REXML::Document.new(element_cell_state(f, :xml_export)).root
    attribs = {}
    content.attributes.each {|a, b| attribs[a] = b }
    assert_equal({"name" => "fooform"}, attribs)
    pos = content.get_elements('rulerpos/pos').to_a.map(&:get_text).map(&:value)
    assert_equal(["1.1", "1.2", "3.1234"], pos)
    line = content.get_elements('line')
    assert_equal(1, line.length)

    f.form_lines << FormLine.new
    content = REXML::Document.new(element_cell_state(f, :xml_export)).root
    line = content.get_elements('line')
    assert_equal(2, line.length)
  end

  def test_xml_import
    d = REXML::Document.new(<<'EOF').root
<form name="fooform">
  <rulerpos>
    <pos>1.23</pos>
    <pos>4.567</pos>
  </rulerpos>
  <line />
  <line />
</form>
EOF
    f = Form.new
    element_cell_state(f, :xml_import, :xml => d)

    assert_equal "fooform", f.name
    assert_equal [1.23, 4.567], f.ruler_positions
    assert_equal 2, f.form_lines.length
  end
end
