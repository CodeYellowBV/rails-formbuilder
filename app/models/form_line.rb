# A FormLine specifies a line in a Form (duh!)
# It can be part of either a Form or a FormGroup.
# It holds FormItems.
class FormLine < ActiveRecord::Base
  belongs_to :line_group, :polymorphic => true

  has_many :form_items, :order => "#{ActiveRecord::Base.connection.quote_column_name('offset')} ASC", :dependent => :destroy

  validate :validate_form_line

  def validate_form_line
    errors.add(:line_group, "Must be a form or formgroup") unless self.line_group.is_a?(FormGroup) || self.line_group.is_a?(Form)
  end

  acts_as_list :scope => :line_group
end
