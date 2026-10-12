# Shared helpers for pulling data from Airtable without slowing pages down.
module AirtableSync
  extend ActiveSupport::Concern

  class_methods do
    # Runs the block at most once per `every`, unless force is true.
    # The timestamp is written first so busy pages don't all sync at once.
    def throttled_sync(key, every:, force: false)
      cache_key = "airtable_sync/#{key}"
      return false if !force && Rails.cache.read(cache_key)

      Rails.cache.write(cache_key, Time.current.to_i, expires_in: every)
      yield
      true
    rescue StandardError => e
      Rails.logger.error("[AirtableSync] #{key}: #{e.class}: #{e.message}")
      false
    end

    def airtable_configured?
      ENV['airtable_api_key'].present? && Setting.last.present?
    end

    def airtable_table(table_id)
      Airtable::Client.new(ENV['airtable_api_key']).table(Setting.last.airtable_base_id, table_id)
    end
  end
end
