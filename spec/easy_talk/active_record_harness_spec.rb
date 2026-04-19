# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActiveRecord harness', :active_record do
  it 'round-trips a plain json attribute in memory' do
    klass = build_active_record_class(columns: { settings: :json }) do
      attribute :settings, :json
    end

    record = klass.create!(settings: { 'name' => 'Ada' })

    expect(klass.find(record.id).settings).to include('name' => 'Ada')
  end
end
