class RenameParagraphStaticToInformationalStatic < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("UPDATE form_items SET type='InformationalStatic' WHERE type='ParagraphStatic'")
    # Ideally, we'd change the 'value' property of the heading to be prefixed with the proper number of # marks, but that's
    # impossible to do portably.
    ActiveRecord::Base.connection.execute("DELETE FROM form_item_properties p USING form_items i WHERE i.id = p.form_item_id AND i.type='HeadingStatic' AND p.name != 'contents'")
    ActiveRecord::Base.connection.execute("UPDATE form_items SET type='InformationalStatic' WHERE type='HeadingStatic'")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "You can't reverse this migration"
  end
end
