require 'net/http'
require 'json'

# The one "main" task for the shift that is happening right now, read live from
# the Airtable Tasks table and shown as a banner at the top of the Tasks page.
#
# Nothing is saved to the database. The answer is cached for a few minutes so
# the page stays fast and Airtable isn't called on every page load.
#
# Which Airtable task counts as "current" is controlled by Heroku config vars,
# so it can be changed later without touching this code:
#
#   AIRTABLE_SHIFT_TASK_VIEW     Name of a view in the Airtable Tasks table.
#                                The first task in that view is shown. (Recommended.)
#   AIRTABLE_SHIFT_TASK_FORMULA  Optional Airtable formula. Only tasks where it is
#                                true are considered.
#
# If neither is set, the newest task created in Airtable in the last 12 hours
# is shown.
class ShiftTask
  NAME_FIELD = 'Name'.freeze
  DESCRIPTION_FIELD = 'Description:'.freeze
  DEFAULT_FORMULA = "IS_AFTER(CREATED_TIME(), DATEADD(NOW(), -12, 'hours'))".freeze
  CACHE_KEY = 'shift_task/current/v1'.freeze
  CACHE_FOR = 5 * 60 # seconds

  attr_reader :airtable_id, :name, :description

  def initialize(attrs)
    @airtable_id = attrs['airtable_id']
    @name = attrs['name']
    @description = attrs['description']
  end

  # Returns a ShiftTask, or nil when there is no current task or Airtable
  # can't be reached. It never raises, so the Tasks page always loads.
  def self.current
    attrs = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_FOR, skip_nil: true) { fetch_from_airtable }
    attrs ? new(attrs) : nil
  rescue StandardError => e
    Rails.logger.error("[ShiftTask] #{e.class}: #{e.message}")
    nil
  end

  def self.clear_cache
    Rails.cache.delete(CACHE_KEY)
  end

  def self.fetch_from_airtable
    setting = Setting.last
    api_key = ENV['airtable_api_key'].to_s
    return nil if setting.nil? || api_key.empty?

    view = ENV['AIRTABLE_SHIFT_TASK_VIEW'].to_s.strip
    formula = ENV['AIRTABLE_SHIFT_TASK_FORMULA'].to_s.strip
    formula = DEFAULT_FORMULA if view.empty? && formula.empty?

    params = { 'pageSize' => 100 }
    params['view'] = view unless view.empty?
    params['filterByFormula'] = formula unless formula.empty?

    uri = URI("https://api.airtable.com/v0/#{setting.airtable_base_id}/#{setting.tasks_table_id}")
    uri.query = URI.encode_www_form(params)
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{api_key}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 4, read_timeout: 4) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[ShiftTask] Airtable returned #{response.code}: #{response.body.to_s[0, 300]}")
      return nil
    end

    records = JSON.parse(response.body)['records'] || []
    records = records.select { |record| field(record, NAME_FIELD).to_s.strip != '' }
    # A view keeps its own sort order. Without one, show the newest task first.
    records = records.sort_by { |record| record['createdTime'].to_s }.reverse if view.empty?

    record = records.first
    return nil unless record

    {
      'airtable_id' => record['id'],
      'name' => field(record, NAME_FIELD).to_s.strip,
      'description' => field(record, DESCRIPTION_FIELD).to_s
    }
  end

  # Look a field up by name, ignoring upper/lower case.
  def self.field(record, name)
    fields = record['fields'] || {}
    return fields[name] if fields.key?(name)

    match = fields.keys.find { |key| key.casecmp?(name) }
    match ? fields[match] : nil
  end
end
