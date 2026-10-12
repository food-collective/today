# Don't let a slow Airtable response hang a page for a minute.
Rails.application.config.after_initialize do
  Airtable::Table.default_timeout(8) if defined?(Airtable::Table)
end
