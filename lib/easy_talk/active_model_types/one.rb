# frozen_string_literal: true

require 'active_model'
require 'active_support/json'

module EasyTalk
  module ActiveModelTypes
    class One < ActiveModel::Type::Value
      def initialize(schema_class)
        @schema_class = schema_class
        super()
      end

      def type
        :json
      end

      def serialize(value)
        return nil if value.nil?

        ActiveSupport::JSON.encode(normalize_serializable_value(value))
      end

      def changed?(old_value, new_value, _new_value_before_type_cast)
        normalize_serializable_value(old_value) != normalize_serializable_value(new_value)
      end

      def changed_in_place?(raw_old_value, new_value)
        normalize_serializable_value(deserialize(raw_old_value)) != normalize_serializable_value(new_value)
      end

      private

      def cast_value(value)
        case value
        when @schema_class
          value
        when String
          build_instance(parse_json(value))
        when Hash
          build_instance(value)
        else
          return build_instance(value.to_h) if value.respond_to?(:to_h)

          raise TypeError, "expected nil, String, Hash, or #{@schema_class.name}, got #{value.class}"
        end
      end

      def parse_json(value)
        decoded = ActiveSupport::JSON.decode(value)
        raise TypeError, "expected JSON object for #{@schema_class.name}, got #{decoded.class}" unless decoded.is_a?(Hash)

        decoded
      rescue JSON::ParserError => e
        raise TypeError, "expected valid JSON for #{@schema_class.name}: #{e.message}"
      end

      def build_instance(attributes)
        return attributes if attributes.is_a?(@schema_class)

        raise TypeError, "expected Hash attributes for #{@schema_class.name}, got #{attributes.class}" unless attributes.is_a?(Hash)

        @schema_class.new(cast_attributes(attributes, schema_class: @schema_class))
      end

      def cast_attributes(attributes, schema_class:)
        schema_definition = schema_class.schema_definition
        properties = schema_definition.respond_to?(:schema) ? schema_definition.schema.fetch(:properties, {}) : {}
        casted_attributes = EasyTalk.deep_dup(attributes)

        properties.each do |property_name, property_definition|
          key = if casted_attributes.key?(property_name)
                  property_name
                elsif casted_attributes.key?(property_name.to_s)
                  property_name.to_s
                end

          next unless key

          casted_attributes[key] = cast_property_value(property_definition[:type], casted_attributes[key])
        end

        casted_attributes
      end

      def cast_property_value(type, value)
        return nil if value.nil?

        unwrapped_type = EasyTalk::TypeIntrospection.nilable_type?(type) ? EasyTalk::TypeIntrospection.extract_inner_type(type) : type

        if unwrapped_type.is_a?(T::Types::TypedArray)
          return Array(value).map { |item| cast_property_value(unwrapped_type.type, item) }
        end

        if unwrapped_type.is_a?(EasyTalk::Types::Tuple)
          return Array(value).each_with_index.map do |item, index|
            tuple_type = unwrapped_type.types[index] || unwrapped_type.types.last
            cast_property_value(tuple_type, item)
          end
        end

        return ActiveModel::Type::Boolean.new.cast(value) if EasyTalk::TypeIntrospection.boolean_type?(unwrapped_type)

        type_class = EasyTalk::TypeIntrospection.get_type_class(unwrapped_type)

        if easy_talk_class?(type_class)
          return value if value.is_a?(type_class)
          return type_class.new(cast_attributes(value, schema_class: type_class)) if value.is_a?(Hash)
        end

        return ActiveModel::Type::Integer.new.cast(value) if type_class == Integer
        return ActiveModel::Type::Float.new.cast(value) if type_class == Float
        return ActiveModel::Type::Decimal.new.cast(value) if type_class == BigDecimal
        return ActiveModel::Type::String.new.cast(value) if type_class == String

        value
      end

      def easy_talk_class?(type_class)
        type_class.is_a?(Class) && (type_class.include?(EasyTalk::Model) || type_class.include?(EasyTalk::Schema))
      end

      def normalize_serializable_value(value)
        return nil if value.nil?

        casted_value = value.is_a?(@schema_class) ? value : cast(value)
        serializable_value = casted_value.respond_to?(:as_json) ? casted_value.as_json : casted_value

        ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(serializable_value))
      end
    end
  end
end
