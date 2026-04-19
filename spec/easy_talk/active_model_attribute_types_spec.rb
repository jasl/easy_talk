# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EasyTalk ActiveModel attribute types' do
  let(:settings_class) do
    Class.new do
      include EasyTalk::Schema

      def self.name = 'ActiveModelSettings'

      define_schema do
        property :name, String
        property :age, Integer
        property :active, T::Boolean
      end
    end
  end

  let(:record_class) do
    settings = settings_class

    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :settings, settings.to_type
      attribute :items, settings.to_array_type
    end
  end

  it 'casts a single EasyTalk object through ActiveModel::Attributes' do
    record = record_class.new(settings: { 'name' => 'Ada', 'age' => '42', 'active' => 'true' })

    expect(record.settings).to be_a(settings_class)
    expect(record.settings.age).to eq(42)
    expect(record.settings.active).to be(true)
  end

  it 'casts arrays through ActiveModel::Attributes' do
    record = record_class.new(items: [{ 'name' => 'Ada', 'age' => '42', 'active' => 'true' }])

    expect(record.items.first).to be_a(settings_class)
    expect(record.items.first.age).to eq(42)
    expect(record.items.first.active).to be(true)
  end
end
