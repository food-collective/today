class User < ApplicationRecord
  include AirtableSync

  SYNC_EVERY = 12.hours
  EMAIL_COLUMN = 'E-mail:'.freeze
  NAME_COLUMN = 'Full Name'.freeze

  # Copies the member list from Airtable (at most every 12 hours unless forced):
  # adds new members, deactivates people no longer listed, and reactivates
  # people who come back.
  def self.sync_from_airtable(force: false)
    return false unless airtable_configured?

    throttled_sync(:users, every: SYNC_EVERY, force: force) do
      records = airtable_table(Setting.last.users_table_id).all
      names_by_email = {}
      records.each do |record|
        email = record[EMAIL_COLUMN].to_s.strip
        next if email.empty?

        names_by_email[email.downcase] ||= [email, record[NAME_COLUMN].to_s.strip]
      end
      next if names_by_email.empty? # never deactivate everyone because of a bad response

      existing = User.all.group_by { |user| user.email.to_s.downcase }
      transaction do
        names_by_email.each do |key, (email, name)|
          users = existing[key]
          if users.nil?
            User.create!(email: email, name: name.presence || email, active: true)
          elsif users.none?(&:active)
            users.max_by(&:id).update!(active: true)
          end
        end
        existing.each do |key, users|
          next if names_by_email.key?(key)

          users.each { |user| user.update!(active: false) if user.active }
        end
      end
    end
  end

  # Kept for compatibility with the original app.
  def self.populate_from_airtable
    sync_from_airtable(force: true)
  end
end
