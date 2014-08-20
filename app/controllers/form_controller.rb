require 'rexml/document'

class FormController < ApplicationController
  layout :select_layout

  def new
    @form = Form.create(:name => 'autosave')
    # Redirect to prevent a new form from being created when the user refreshes the page
    redirect_to :action => 'edit', :id => @form.id
  end

  def edit
    @form = Form.find(params[:id])
  end

  def list
    @title = "Form overview"
    @forms = Form.paginate(:page => params[:page], :order => "updated_at DESC, created_at DESC")
  end

  def save
    @form = Form.find(params[:id])
    @form.update_attributes(params[:form])
    @form.save
    if request.xhr?
      render :nothing => true
    else
      redirect_to :action => 'list'
    end
  end

  def destroy
    if request.method == 'POST'
      Form.destroy(params[:id])
    else
      flash[:error] = "This action cannot be performed in this way"
    end
    redirect_to(:action => "list")
  end

  def new_item
    @form = Form.find(params[:id])
    if params[:line_id]
      @line = FormLine.find(params[:line_id])
    else
      @line = FormLine.new()
      if params[:formgroup_id]
        @formgroup = FormGroup.find(params[:formgroup_id])
        @formgroup.form_lines << @line
      else
        @form.form_lines << @line
      end
    end
    @item = params[:item_class].camelize.constantize.new(params[:item].update({:form_id => @form.id}))
    @line.form_items << @item
  end

  def rearrange
    (params[:canvas] || {}).each_pair do |pos, line|
      FormLine.find(line[:id]).update_attributes({:position => pos.to_i + 1})
    end
    render :nothing => true
  end

  def update_ruler
    @form = Form.find(params[:id])
    @form.ruler_positions = (params[:positions] || []).map{|pos| pos.to_f}
    @form.save
    render :nothing => true
  end

  def export
    @form = Form.find(params[:id])
    render :action => "export.xml.builder", :layout => false
  end

  def import
    if request.method == 'POST'
      @form = Form.new()
      begin
        @xml = REXML::Document.new(params[:file]).root
        # There's a weird "uninitialized stream" error that you get when
        # the browser sends no proper data. (try refreshing and reposting
        # the form, or some such)
      rescue IOError
        @xml = nil
      end

      # A bit of a hack here:
      # We call the form cell, discarding its rendered output, solely for the
      # purpose of parsing the XML to a form.  It is expected to mutate this
      # form object, thereby "returning" it.
      render_cell(:form, :xml_import, :element => @form, :xml => @xml)
      if @form.save
        flash[:message] = "Form '#{@form.name}' successfully imported"
        redirect_to :action => "edit", :id => @form.id
      else
        flash.now[:error] = "Form could not be imported due to errors in the file!"
      end
    end
  end

private
  def select_layout
    case action_name
    when "list", "import" then "simple"
    else "form_builder"
    end
  end
end
