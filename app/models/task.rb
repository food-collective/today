class Task < ApplicationRecord
  validates :name, presence: true

  # Everyone sees hand-added tasks (Low and High priority). Tasks that came
  # from Airtable are only shown to the people assigned to them.
  def self.visible_to(user)
    everyone = where(priority: [1, 3])
    return everyone unless user&.email.present?

    everyone.or(where('assigneduserstring LIKE ?', "%#{sanitize_sql_like(user.email)}%"))
  end
end
