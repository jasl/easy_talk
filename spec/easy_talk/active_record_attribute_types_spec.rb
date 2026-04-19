# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EasyTalk ActiveRecord attribute types', :active_record do
  let(:schema_settings_class) do
    profile_class = Class.new do
      include EasyTalk::Schema

      def self.name = 'ArProfileSettings'

      define_schema do
        property :title, String
      end
    end

    Class.new do
      include EasyTalk::Schema

      def self.name = 'ArSchemaSettings'

      define_schema do
        property :name, String
        property :age, Integer
        property :active, T::Boolean
        property :profile, profile_class, optional: true
      end
    end
  end

  let(:model_settings_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'ArModelSettings'

      define_schema do
        property :name, String
        property :age, Integer
      end
    end
  end

  let(:additional_class) do
    Class.new do
      include EasyTalk::Schema

      def self.name = 'ArAdditionalSettings'

      define_schema do
        property :name, String
        additional_properties true
      end
    end
  end

  let(:record_class) do
    schema_settings = schema_settings_class
    model_settings = model_settings_class
    additional = additional_class

    build_active_record_class(
      columns: {
        settings: :json,
        items: :json,
        model_settings: :json,
        model_items: :json,
        extras: :json
      }
    ) do
      attribute :settings, schema_settings.to_type
      attribute :items, schema_settings.to_array_type
      attribute :model_settings, model_settings.to_type
      attribute :model_items, model_settings.to_array_type
      attribute :extras, additional.to_type
    end
  end

  it 'round-trips a single EasyTalk::Schema object' do
    record = record_class.create!(settings: { 'name' => 'Ada', 'age' => '42', 'active' => 'true' })
    reloaded = record_class.find(record.id)

    expect(reloaded.settings).to be_a(schema_settings_class)
    expect(reloaded.settings.age).to eq(42)
    expect(reloaded.settings.active).to be(true)
  end

  it 'round-trips an array of EasyTalk::Schema objects' do
    record = record_class.create!(items: [{ 'name' => 'Ada', 'age' => '42', 'active' => 'true' }])
    reloaded = record_class.find(record.id)

    expect(reloaded.items.first).to be_a(schema_settings_class)
    expect(reloaded.items.first.age).to eq(42)
  end

  it 'round-trips an EasyTalk::Model object' do
    record = record_class.create!(model_settings: { 'name' => 'Ada', 'age' => '42' })
    reloaded = record_class.find(record.id)

    expect(reloaded.model_settings).to be_a(model_settings_class)
    expect(reloaded.model_settings.age).to eq(42)
  end

  it 'round-trips an array of EasyTalk::Model objects' do
    record = record_class.create!(model_items: [{ 'name' => 'Ada', 'age' => '42' }])
    reloaded = record_class.find(record.id)

    expect(reloaded.model_items.first).to be_a(model_settings_class)
    expect(reloaded.model_items.first.age).to eq(42)
  end

  it 'preserves additional properties when enabled' do
    record = record_class.create!(extras: { 'name' => 'Ada', 'nickname' => 'Ace' })
    reloaded = record_class.find(record.id)

    expect(reloaded.extras.as_json).to include('nickname' => 'Ace')
  end

  it 'does not mark semantically identical reassignment as dirty' do
    record = record_class.create!(
      settings: {
        'name' => 'Ada',
        'age' => 42,
        'active' => true,
        'profile' => { 'title' => 'Captain' }
      }
    )
    reloaded = record_class.find(record.id)

    reloaded.settings = {
      'name' => 'Ada',
      'age' => '42',
      'active' => 'true',
      'profile' => { 'title' => 'Captain' }
    }

    expect(reloaded).not_to be_changed
  end

  it 'detects in-place mutation as dirty' do
    record = record_class.create!(settings: { 'name' => 'Ada', 'age' => 42, 'active' => true })
    reloaded = record_class.find(record.id)

    reloaded.settings.name = 'Grace'

    expect(reloaded.will_save_change_to_settings?).to be(true)
  end
end
