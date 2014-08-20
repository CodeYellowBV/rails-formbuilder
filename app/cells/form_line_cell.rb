require 'rexml/xpath'

# A FormLineCell belongs to a FormLine.  Whenever it's supposed to render an
# *instantiated* line (as per render_form_element from ApplicationHelper), it
# will have a @line value available throughout all its methods.
class FormLineCell < Cell::Base
  helper :application

  def initialize(controller, options={})
    super
    @controller = controller
    @cell = self
    @line = @opts[:element]
    @form = @opts[:form]
    @form_response = @opts[:form_response]
    @opts.delete(:element)
    @opts.delete(:form_response)
  end

  # Get the class of the model that belongs to this Cell.
  def self.model_class
    self.name.sub(/Cell$/, '').constantize
  end

  # Show the line and all that's inside
  def show; render; end

  # Edit this line for a response
  def edit_response
    render :view => 'show'
  end

  # Show this line for a response
  def show_response
    render :view => 'show'
  end

  def xml_export; render; end

  def xml_import
    REXML::XPath.each(@opts[:xml], 'item') do |el|
      begin
        type = el.attribute(:type).to_s
        item = type.camelize.constantize.new(:form_line => @line, :form => @form)
        @line.form_items << item
        render_cell_to_string(type, :xml_import, :element => item, :xml => el, :form => @form)
#      rescue NameError
        # Just ignore unknown form item types
      end
    end
    ""
  end
end
