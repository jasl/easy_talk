# frozen_string_literal: true

require 'active_model'
require 'active_support/json'

module EasyTalk
  module ActiveModelTypes
    class Many < ActiveModel::Type::Value
      def initialize(schema_class)
        @schema_class = schema_class
        @single_type = schema_class.to_type
        super()
      end

      def type
        :array
      end

      def cast(value)
        case value
        when nil
          nil
        when String
          cast(parse_json_array(value))
        when Array
          value.map { |item| @single_type.cast(item) }
        else
          raise TypeError, "expected nil, Array, or JSON string, got #{value.class}"
        end
      end

      alias deserialize cast

      def serialize(value)
        return nil if value.nil?

        ActiveSupport::JSON.encode(normalize_array(value))
      end

      def changed?(old_value, new_value, _new_value_before_type_cast)
        normalize_array(old_value) != normalize_array(new_value)
      end

      def changed_in_place?(raw_old_value, new_value)
        normalize_array(deserialize(raw_old_value)) != normalize_array(new_value)
      end

      private

      def parse_json_array(value)
        decoded = ActiveSupport::JSON.decode(value)
        raise TypeError, "expected JSON array for #{@schema_class.name}[]" unless decoded.is_a?(Array)

        decoded
      rescue JSON::ParserError => e
        raise TypeError, "expected valid JSON array for #{@schema_class.name}[]: #{e.message}"
      end

      def normalize_array(value)
        return nil if value.nil?

        array = value.is_a?(Array) ? value : cast(value)
        serializable = array.map do |item|
          serialized_item = @single_type.serialize(item)
          serialized_item.nil? ? nil : ActiveSupport::JSON.decode(serialized_item)
        end

        ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(serializable))
      end
    end
  end
end
