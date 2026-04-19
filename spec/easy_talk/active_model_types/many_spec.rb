# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ActiveModelTypes::Many do
  let(:schema_class) do
    Class.new do
      include EasyTalk::Schema

      def self.name = 'PlanItem'

      define_schema do
        property :label, String
        property :count, Integer
      end
    end
  end

  let(:model_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'PlanItemModel'

      define_schema do
        property :label, String
      end
    end
  end

  it 'is exposed on both Schema and Model classes' do
    expect(schema_class.to_array_type).to be_a(described_class)
    expect(model_class.to_array_type).to be_a(described_class)
  end

  it 'casts arrays of hashes into EasyTalk instances' do
    value = schema_class.to_array_type.cast([{ 'label' => 'a', 'count' => '1' }])

    expect(value.map(&:class)).to eq([schema_class])
    expect(value.first.count).to eq(1)
  end

  it 'deserializes JSON arrays' do
    value = schema_class.to_array_type.deserialize('[{"label":"a","count":"1"}]')

    expect(value.first).to be_a(schema_class)
    expect(value.first.count).to eq(1)
  end

  it 'serializes arrays to JSON' do
    json = schema_class.to_array_type.serialize([schema_class.new(label: 'a', count: 1)])

    expect(ActiveSupport::JSON.decode(json)).to eq([{ 'label' => 'a', 'count' => 1 }])
  end

  it 'raises on malformed JSON arrays' do
    expect do
      schema_class.to_array_type.deserialize('{broken')
    end.to raise_error(TypeError, /JSON array/)
  end

  it 'compares semantic equality for dirty tracking' do
    type = schema_class.to_array_type
    old_value = type.cast([{ 'label' => 'a', 'count' => '1' }])
    new_value = type.cast([{ label: 'a', count: 1 }])

    expect(type.changed?(old_value, new_value, nil)).to be(false)
    expect(type.changed_in_place?(type.serialize(old_value), new_value)).to be(false)
  end

  it 'normalizes raw hashes and instances consistently for dirty tracking' do
    type = schema_class.to_array_type
    old_value = [{ 'label' => 'a', 'count' => '1' }]
    new_value = [schema_class.new(label: 'a', count: 1)]

    expect(type.changed?(old_value, new_value, nil)).to be(false)
  end
end
