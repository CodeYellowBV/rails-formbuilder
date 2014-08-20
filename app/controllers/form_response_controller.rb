class FormResponseController < ApplicationController
  layout :select_layout

  def new
    @form = Form.find(params[:id])
    @form_response = FormResponse.new(:form_id => @form.id)

    if request.post?
      (params[:form_items] || {}).each_pair do |id, value|
        item = FormItem.find(id)
        item_value = FormItemValue.new(:form_item => item, :form_response => @form_response, :value => value)
        @form_response.form_item_values << item_value
      end

      if @form_response.save
        flash[:message] = "Your response has been saved"
        redirect_to :action => 'edit', :id => @form_response.id
        return
      else
        flash[:error] = "Your response could not be saved!"
      end
    end
    render :action => 'edit'
  end

  def edit
    @form_response = FormResponse.find(params[:id], :include => [:form, :form_item_values])
    @form = @form_response.form
    if request.post?
      to_delete = @form_response.form_item_values.select {|fiv| params[:form_items][fiv.form_item.id.to_s].blank? }
      to_delete.each {|x| @form_response.form_item_values.delete(x) }

      (params[:form_items] || {}).each_pair do |id, value|
        next if value.blank?
        if (form_item_value = @form_response.form_item_values.detect {|fiv| fiv.form_item.id.to_i == id.to_i })
          form_item_value.update_attributes(:value => value)
        else
          item = FormItem.find(id)
          item_value = FormItemValue.new(:form_item => item, :form_response => @form_response, :value => value)
          @form_response.form_item_values << item_value
        end
      end

      if @form_response.save
        flash[:message] = "Your response has been saved"
        redirect_to :controller => "form_response", :action => "show", :id => @form_response.id
      else
        flash[:error] = "Your response could not be saved!"
      end
    end
  end

  def list
    @form = Form.find(params[:id])
    @title = "'#{@form.name}' responses"
    @responses = FormResponse.where(:form_id => @form.id).order("updated_at DESC, created_at DESC").paginate(:page => params[:page])
  end

  def show
    @form_response = FormResponse.find(params[:id])
    @title = "Response for form '#{@form_response.form.name}'"
  end

  def destroy
    if request.method == 'POST'
      FormResponse.destroy(params[:id])
    else
      flash[:error] = "This action cannot be performed in this way"
    end
    redirect_to(:action => "list", :id => params[:form_id])
  end

private
  def select_layout
    case action_name
    when "list", "show" then "simple"
    else "form_response"
    end
  end
end
