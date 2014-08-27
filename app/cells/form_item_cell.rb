require 'rexml/xpath'

# A FormItemCell belongs to a FormItem.  Whenever it's supposed to render an
# *instantiated* item (as per render_form_element from ApplicationHelper), it
# will have a @item value available throughout all its methods.
#
# If it is rendered for a form response, the @response variable
# will point to the response.  This way we can get at the current
# value.
#
# Every subclass of FormItem must have a matching Cell.
class FormItemCell < Cell::Base
  helper :application

  def initialize(controller, options={})
    super
    @cell = self
    @controller = controller
    @item = @opts[:element]
    @form = @opts[:form]
    @form_response = @opts[:form_response]
    @item_value = @form_response.form_item_values.detect {|v| v.form_item_id == @item.id } if @form_response
    @opts.delete(:element)
    @opts.delete(:form_response)
  end

  # Get the class of the model that belongs to this Cell.
  def self.model_class
    self.name.sub(/Cell$/, '').constantize
  end

  # Render the tool for this particular item.  Defaults to
  # an image with the underscored class name of the tool,
  # with an extension of .png.  Alt text is the item_name.
  def tool; render; end

  # Render the item's form element
  def show; render; end

  # To be filled in by the specific item type
  def show_body; render; end

  # Render the item's form element for filling it in
  def edit_response; render; end

  # To be filled in by the specific item type
  def edit_response_body; render; end

  # Render the item's form response for this item
  def show_response; render; end

  # Get the properties
  def properties; render; end

  # Get the attributes
  def attributes; render; end

  # Render a particular property.  It checks if there is a
  # render_<property name>_property method and calls it if there is.
  # Otherwise, it will simply call render_generic_text_property.
  #
  # The property name is taken from @opts[:property].
  #
  # It will set @property to the property for the item, or
  # a new property if that property does not yet exist.
  #
  # It will append an UL of class "errors" to the resulting output
  def render_property
    @property = @item.get_property(@opts[:property]) || FormItemProperty.new(:name => @opts[:property], :form_item => @item)
    if self.respond_to?("render_#{@opts[:property]}_property")
      res = self.render_state "render_#{@opts[:property]}_property"
    else
      res = self.render_state :render_generic_text_property
    end

    # Append error list
    unless @property.errors.empty?
      res += @property.errors[:value].inject("<ul class='errors'>") do |str, err|
        str + "<li>#{ERB::Util.html_escape err}</li>"
      end + "</ul>"
    end
    raw(res)
  end

  def render_property_label
    @property ||= @opts[:property] # XXX Clean this up!
    raw("<label title='#{ERB::Util.html_escape(@item.class.get_property_description(@property.name))}' for='#{property_id}'>#{ERB::Util.html_escape(@item.class.get_property_description(@property.name))}</label>")
  end

  # Render a property as a generic text input control.
  def render_generic_text_property
    self.render_state(:render_property_label) + raw("<input id='#{property_id}' type='text' name='properties[#{@property.name}]' value='#{ERB::Util.html_escape(@property.value)}' />")
  end

  # Render the conditional property as a textarea with a short help text
  def render_conditional_property
    render
  end

  # Render the error messages and such for the item, after it has been validated (by a save)
  def errors
    render
  end

  # Style string for simulated absolute positioning with an offset in percentages from the
  # left of the current node's parent.
  def positioning_style
    "position: relative; left: 100%; margin-left: -#{100 - @item.offset}%; float: left;"
  end

  def xml_export; render; end

  # Export a particular property to XML.  It checks if there is a
  # xml_export_<property name>_property method and calls it if there is.
  # Otherwise, it will simply call xml_export_generic_text_property.
  #
  # The property name is taken from @opts[:property].
  #
  # It will set @property to the property for the item, or
  # a new property if that property does not yet exist.
  def xml_export_property
    @property = @item.get_property(@opts[:property]) || FormItemProperty.new(:name => @opts[:property], :form_item => @item)
    if self.respond_to?("xml_export_#{@opts[:property]}_property")
      res = self.render_state "xml_export_#{@opts[:property]}_property"
    else
      res = self.render_state :xml_export_generic_text_property
    end
    raw(res)
  end

  def xml_export_generic_text_property
    @property.value
  end

  def xml_import
    @item.offset = @opts[:xml].attribute(:offset).to_s.to_f
    @item.variable_name = @opts[:xml].attribute(:variable_name).to_s
    REXML::XPath.each(@opts[:xml], 'property') do |xml|
      @xml = xml
      self.render_state(:xml_import_property)
    end
    ""
  end

  # Import a particular property from XML.  It checks if there is a
  # xml_import_<property name>_property method and calls it if there is.
  # Otherwise, it will simply call xml_import_generic_text_property.
  #
  # The property name is taken from @xml, assuming it has a name
  #
  # It will set @property to the new property for the item.
  def xml_import_property
    return unless @xml.attribute(:name)
    
    name = @xml.attribute(:name).to_s

    @property = FormItemProperty.new(:name => name, :form_item => @item)
    @item.form_item_properties << @property
    if self.respond_to?("xml_import_#{name}_property")
      self.render_state("xml_import_#{name}_property")
    else
      self.render_state(:xml_import_generic_text_property)
    end
    ""
  end

  def xml_import_generic_text_property
    @property.value = @xml.text.to_s
    ""
  end

protected
  # XXX What's "special" about this method?
  def property_id
    "item#{@item.id}-#{@property.name}-property"
  end
  helper_method :property_id
end
