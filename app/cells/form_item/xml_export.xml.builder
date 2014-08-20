xml.item :type => @item.class.name.underscore, :offset => @item.offset, :variable_name => @item.variable_name do
  @item.form_item_properties.each do |prop|
    xml.property({:name => prop.name}, render_form_element(@item, :xml_export_property, :property => prop.name))
  end
end
