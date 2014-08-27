# The cell for Form.  This cell renders all things that are not item-specific.
class FormCell < Cell::Base
  helper :application

  def initialize(controller, options={})
    super
    @controller = controller
    @cell = self
    @form = options[:element]
    @form_response = options[:form_response]
    options.delete(:element)
    options.delete(:form_response)
  end

  # Render the toolbox.  This is an ul with li's in it which contain the tools.
  # The li's are made draggable.
  def toolbox; render; end

  # Show the form.  This renders the canvas on which to draw the tools.
  def show; render; end

  # Render the form properties element
  def properties; render; end

  # Show the form for filling it in
  def edit_response; render; end

  # Show the filled in form as response
  def show_response
    render :view => 'edit_response'
  end

  def xml_export; render; end

  def xml_import
    @form.name = options[:xml].attribute(:name).to_s
    @form.ruler_positions = REXML::XPath.match(options[:xml], 'rulerpos/pos').map {|el| el.text.to_f }
    REXML::XPath.each(options[:xml], 'line') do |el|
      line = FormLine.new(:line_group => @form)
      @form.form_lines << line
      render_cell_to_string(:form_line, :xml_import, :element => line, :xml => el, :form => @form)
    end
    "Don't use this response string! The input @form has been mutated to reflect the input @xml structure."
  end
end
