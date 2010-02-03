require 'acts_as_acts_as/requirements'

# Methods available _at the same level as_ examples, including methods that
# themselves define examples, before, and after blocks
module ActsAsActsAs::GroupMacros

  # Example Usage:
  #   acts_as :acts_as_billable do |plugin|
  #     plugin.should require_methods(
  #       :billable_amount,
  #       :billable_description,
  #       :billable_type,
  #       :billable_user,
  #       :billable_mfk
  #     )
  #     plugin.should define_methods(
  #       :billed?
  #     )
  #     plugin.with(:bill_by_date => true).should require_columns(
  #       [:effective_start_date, :datetime],
  #       [:effective_end_date,   :datetime],
  #       [:quantity,             :integer]
  #     )
  #   end
  def acts_as(acts_as_method, &block)
    # Now use our new object to let the block build up requirements
    collector = ActsAsActsAs::Requirements::Collector.new
    verifier = ActsAsActsAs::Requirements::Verifier.new(acts_as_method)

    extend ActsAsActsAs::Requirements::Collector::Context

    yield collector


    describe "Acts As Plugin #{acts_as_method}" do
      verifier.verify_requirements(collector)
    end

    before(:all) do
      ActsAsBillable::BillableObjects.classes_using_billing = []

      @valid_model = tableless_model(
        :columns => collector.all_requirements[:require_columns],
        :methods => collector.all_requirements[:require_methods]
      )

      @valid_model.send(acts_as_method)

      @model_opts = {
        :columns => collector.all_requirements[:require_columns],
        :methods => collector.all_requirements[:require_methods]
      }

      @valid_model_with_table = temp_model(@model_opts)
      @valid_model_with_table.send(acts_as_method)
    end

    after(:all) do
      drop_temp_model(@valid_model_with_table)
    end

  end
end
