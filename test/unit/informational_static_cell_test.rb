require 'test_helper'

class InformationalStaticCellTest < ActiveSupport::TestCase
  fixtures :forms, :form_lines

  def test_basic_bluecloth_parsing
    form = forms(:personal_info_form)
    line = form_lines(:personal_line1)

    i = InformationalStatic.new(:form => form, :form_line => line)
    i.save
    i.store_properties(:contents => "# This is a test\nMore breakage & such things?")
    i.save
    text = element_cell_state(i, :show_body)
    # This is a *bit* overspecific: the newlines shouldn't matter
    assert_equal("<h1>This is a test</h1>\n\n<p>More breakage &amp; such things?</p>", text)
  end
end
