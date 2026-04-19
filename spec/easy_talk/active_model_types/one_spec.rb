# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe EasyTalk::ActiveModelTypes::One do
  let(:nested_schema_class) do
    Class.new do
      include EasyTalk::Schema

      def self.name = 'NestedPlanSettings'

      define_schema do
        property :title, String
      end
    end
  end

  let(:schema_class) do
    nested = nested_schema_class

    Class.new do
      include EasyTalk::Schema

      def self.name = 'PlanSettings'

      define_schema do
        property :name, String
        property :age, Integer
        property :active, T::Boolean
        property :amount, BigDecimal, optional: true
        property :scores, T::Array[Integer], optional: true
        property :location, T::Tuple[String, Integer], optional: true
        property :profile, nested, optional: true
      end
    end
  end

  let(:model_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'PlanSettingsModel'

      define_schema do
        property :name, String
      end
    end
  end

  it 'is exposed on both Schema and Model classes' do
    expect(schema_class.to_type).to be_a(described_class)
    expect(model_class.to_type).to be_a(described_class)
  end

  it 'casts primitives, arrays, tuples, and nested EasyTalk classes' do
    value = schema_class.to_type.cast(
      'name' => 123,
      'age' => '42',
      'active' => 'false',
      'amount' => '12.50',
      'scores' => ['1', 2, '3'],
      'location' => [100, '7'],
      'profile' => { 'title' => 'Captain' }
    )

    expect(value).to be_a(schema_class)
    expect(value.name).to eq('123')
    expect(value.age).to eq(42)
    expect(value.active).to be(false)
    expect(value.amount).to eq(BigDecimal('12.5'))
    expect(value.scores).to eq([1, 2, 3])
    expect(value.location).to eq(['100', 7])
    expect(value.profile).to be_a(nested_schema_class)
    expect(value.profile.title).to eq('Captain')
  end

  it 'serializes an EasyTalk instance to JSON' do
    json = schema_class.to_type.serialize(schema_class.new(name: 'Ada', age: 7, active: true))

    expect(ActiveSupport::JSON.decode(json)).to include('name' => 'Ada', 'age' => 7, 'active' => true)
  end

  it 'raises on malformed JSON' do
    expect do
      schema_class.to_type.deserialize('{broken')
    end.to raise_error(TypeError, /valid JSON/)
  end

  it 'compares semantic equality for dirty tracking' do
    type = schema_class.to_type
    old_value = type.cast('name' => 'Ada', 'age' => '42', 'active' => 'true')
    new_value = type.cast(name: 'Ada', age: 42, active: true)

    expect(type.changed?(old_value, new_value, nil)).to be(false)
    expect(type.changed_in_place?(type.serialize(old_value), new_value)).to be(false)
  end

  it 'does not produce false positives for nested-object dirty tracking' do
    type = schema_class.to_type
    old_value = type.cast('profile' => { 'title' => 'Captain' })
    new_value = type.cast(profile: { title: 'Captain' })

    expect(type.changed?(old_value, new_value, nil)).to be(false)
    expect(type.changed_in_place?(type.serialize(old_value), new_value)).to be(false)
  end
end
