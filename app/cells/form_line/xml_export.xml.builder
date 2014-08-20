xml.line do
  @line.form_items.each do |item|
    xml << render_form_element(item, :xml_export)
  end
end
