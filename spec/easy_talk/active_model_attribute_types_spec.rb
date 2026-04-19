# frozen_string_literal: true

require 'spec_helper'
require 'date'

RSpec.describe 'EasyTalk ActiveModel attribute types' do
  let(:settings_class) do
    Class.new do
      include EasyTalk::Schema

      def self.name = 'ActiveModelSettings'

      define_schema do
        property :name, String
        property :age, Integer
        property :active, T::Boolean
        property :birthday, Date, optional: true
        property :scheduled_for, DateTime, optional: true
        property :wake_up_at, Time, optional: true
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
    record = record_class.new(
      settings: {
        'name' => 'Ada',
        'age' => '42',
        'active' => 'true',
        'birthday' => '2026-04-20',
        'scheduled_for' => '2026-04-20T15:30:45+02:00',
        'wake_up_at' => '15:30:45+02:00'
      }
    )

    expect(record.settings).to be_a(settings_class)
    expect(record.settings.age).to eq(42)
    expect(record.settings.active).to be(true)
    expect(record.settings.birthday).to eq(Date.new(2026, 4, 20))
    expect(record.settings.scheduled_for.utc.iso8601).to eq('2026-04-20T13:30:45Z')
    expect(record.settings.wake_up_at.utc.iso8601).to eq('2000-01-01T13:30:45Z')
  end

  it 'casts arrays through ActiveModel::Attributes' do
    record = record_class.new(items: [{ 'name' => 'Ada', 'age' => '42', 'active' => 'true' }])

    expect(record.items.first).to be_a(settings_class)
    expect(record.items.first.age).to eq(42)
    expect(record.items.first.active).to be(true)
  end
end
