# Sets up a fresh install from environment variables (the Heroku one-click
# deploy sets these). Safe to run more than once: it never overwrites
# settings that are already filled in.

setting = Setting.last || Setting.new
setting.airtable_base_id = ENV['AIRTABLE_BASE_ID'] if setting.airtable_base_id.blank?
setting.users_table_id = ENV['AIRTABLE_USERS_TABLE_ID'] if setting.users_table_id.blank?
setting.tasks_table_id = ENV['AIRTABLE_TASKS_TABLE_ID'] if setting.tasks_table_id.blank?
setting.announcements_table_id = ENV['AIRTABLE_ANNOUNCEMENTS_TABLE_ID'] if setting.announcements_table_id.blank?
setting.categories = ENV.fetch('TASK_CATEGORIES', 'Inventory, Cleanliness, Beautification') if setting.categories.blank?
setting.password = ENV['ADMIN_PASSWORD'].presence || SecureRandom.hex(12) if setting.admin_password_hash.blank?
setting.save!
puts "Settings ready (Airtable base #{setting.airtable_base_id.presence || 'not set'})."

# A few example tasks so a brand-new copy doesn't look empty. Delete them anytime.
if Task.none? && ENV['SEED_SAMPLE_TASKS'] != 'false'
  now = Time.current
  examples = [
    { name: 'Break down cardboard boxes and take them to recycling', category: 'Cleanliness', priority: 3,
      description: 'Flatten boxes from today’s delivery. Recycling bins are out back by the patio.' },
    { name: 'Make sure all the fresh produce has a price label', category: 'Inventory', priority: 3,
      description: 'Use the label maker by the register. Ask the coordinator on shift if a price is missing.' },
    { name: 'Restock the silverware station', category: 'Inventory', priority: 1,
      description: 'Extra forks and spoons are in the clear bins in the back room.' },
    { name: 'Wipe down the register counter and card reader', category: 'Cleanliness', priority: 1, description: '' },
    { name: 'Refresh the chalkboard sign by the front door', category: 'Beautification', priority: 1,
      description: 'Today’s hours plus anything new on the shelves.' }
  ]
  examples.each_with_index do |attrs, i|
    Task.create!(attrs.merge(added: now - (i + 1).hours, user_add: 'Example task', completed: false))
  end
  Task.create!(name: 'Check the member fridge for expired items', category: 'Cleanliness', priority: 1,
               description: '', added: now - 5.hours, user_add: 'Example task', completed: true,
               user_complete: 'Example task', complete_time: now - 30.minutes)
  puts "Added #{examples.size + 1} example tasks."
end
