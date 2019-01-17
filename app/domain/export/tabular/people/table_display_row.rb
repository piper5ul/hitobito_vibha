module Export::Tabular::People
  class TableDisplayRow < PersonRow
    attr_reader :table_display, :answers

    dynamic_attributes[/^event_question_\d+/] = :event_question_attribute
    def initialize(entry, table_display, format = nil)
      @table_display = table_display
      super(entry, format)
    end

    private

    def value_for(attr)
      table_display.with_permission_check(attr, entry) do
        super
      end
    end

  end
end
