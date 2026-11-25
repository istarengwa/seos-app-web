module ImmutableInputs
  extend ActiveSupport::Concern

  included do
    class_attribute :immutable_input_fields, default: []
    validate :unchanged_inputs, on: :update
  end

  class_methods do
    def immutable_inputs(*fields)
      self.immutable_input_fields = fields.map(&:to_s)
    end
  end

  private

  def unchanged_inputs
    immutable_input_fields.each do |field|
      errors.add(field, "ne peut pas être modifié après création") if will_save_change_to_attribute?(field)
    end
  end
end
