xml.form :name => @form.name do
  xml.rulerpos do 
    @form.ruler_positions.each { |pos| xml.pos(pos) }
  end
  @form.form_lines.each do |line|
    xml << render_form_element(line, :xml_export)
  end
end
