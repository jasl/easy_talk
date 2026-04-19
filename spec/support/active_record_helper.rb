# frozen_string_literal: true

require 'securerandom'

module ActiveRecordSpecHelper
  def ensure_active_record_connection!
    require 'active_record' unless defined?(ActiveRecord::Base)
    return if ActiveRecord::Base.connected?

    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
  end

  def build_active_record_class(columns:, &block)
    ensure_active_record_connection!
    table_name = "records_#{SecureRandom.hex(6)}"

    ActiveRecord::Schema.define do
      suppress_messages do
        create_table table_name, force: true do |table|
          columns.each do |name, type|
            table.public_send(type, name)
          end
        end
      end
    end

    Class.new(ActiveRecord::Base) do
      self.table_name = table_name

      class_eval(&block) if block
    end
  end
end

RSpec.configure do |config|
  config.include ActiveRecordSpecHelper, :active_record
end
