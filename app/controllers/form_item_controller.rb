# Handles FormItems
class FormItemController < ApplicationController
  # Move the item from its current line to another line.
  # If the current line becomes empty after the move, it will
  # be destroyed.
  def move_to_line
    @item = FormItem.find(params[:id])
    old_line_id = @item.form_line_id
    @item.update_attributes(params[:item])
    @old_line = FormLine.find(old_line_id)
    @old_line.destroy if @old_line.form_item_ids.empty?
    @new_line = @item.form_line
  end

  # Show the properties dialog for this item.
  def properties
    @item = FormItem.find(params[:id])
  end

  # Delete a form item from a form.  Its line will be deleted
  # if this was the last item on that line.
  def delete
    @item = FormItem.find(params[:id])
    @item.destroy
    @item.form_line.destroy if @item.form_line.form_item_ids.empty?
  end

  # Update property values
  def update_properties
    @item = FormItem.find(params[:id], :include => {:form => {:form_items => :form_item_properties}})
    @form = @item.form
    @item.update_attributes(params[:item])
    @item.selected = true
    @item.store_properties(params[:properties] || {})
  end

  def show_popup
    @item = FormItem.find(params[:id])
  end

  def submit_popup
    @item = FormItem.find(params[:id])
  end

  def render_data
    @item = FormItem.find(params[:id])
    render_cell(@item.class.name.underscore, :render_data, {:element => @item})
  end

  # Validate the item's value when the user is filling in a response (AJAX)
  def validate
    @form = Form.find(params[:form_id], :include => {:form_items => :form_item_properties})
    @form_response = FormResponse.new(:form => @form)
    items = FormItem.find(params[:form_items].keys + [params[:id]]).group_by(&:id)
    params[:form_items].each_pair do |id, value| # XXX Only one value is expected right now
      @item = items[id.to_i][0]
      @item_value = FormItemValue.new(:form_item => @item, :form_response => @form_response, :value => value)
      @form_response.form_item_values << @item_value
    end
  end

  # Check if an item is supposed to be visible or not and make it so when the user is filling in a response (AJAX)
  def update_visibility
    params[:item_ids] ||= []
    params[:form_items] ||= {}
    @form = Form.find(params[:form_id], :include => {:form_items => :form_item_properties})
    items = FormItem.find(params[:form_items].keys + params[:item_ids], :include => :form_item_properties).group_by(&:id)
    @form_response = FormResponse.new(:form => @form)
    params[:form_items].each_pair do |id, value|
      item = items[id.to_i][0]
      item_value = FormItemValue.new(:form_item => item, :form_response => @form_response, :value => value)
      @form_response.form_item_values << item_value
    end
    @items = params[:item_ids].map{|id| items[id.to_i][0] }.flatten
  end

end
