class Announcement < ApplicationRecord
  include AirtableSync

  SYNC_EVERY = 10.minutes

  scope :upcoming, -> { where('eventtime >= ?', Time.zone.now.beginning_of_day) }
  scope :past, -> { where('eventtime < ?', Time.zone.now.beginning_of_day) }

  # Copies the Events table from Airtable, at most every 10 minutes.
  # Reads every page of results (the old code stopped at the first 100).
  def self.sync_from_airtable(force: false)
    return false unless airtable_configured?

    throttled_sync(:announcements, every: SYNC_EVERY, force: force) do
      records = airtable_table(Setting.last.announcements_table_id).all
      now = Time.current
      rows = records.map do |record|
        author = Array(record[:submitteremail]).first.presence || 'BSFC'
        {
          message: record[:event_name].presence,
          eventtime: parse_time(record[:event_time]),
          audience: author,
          location: record[:event_location].presence,
          created_at: now,
          updated_at: now
        }
      end
      rows.select! { |row| row[:message] }
      next if rows.empty? # never wipe the list because of an empty or failed response

      transaction do
        connection.execute('SELECT pg_advisory_xact_lock(4242001)')
        delete_all
        insert_all(rows)
      end
    end
  end

  def self.parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
