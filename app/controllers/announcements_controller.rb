class AnnouncementsController < ApplicationController
  def index
    if Announcement.none?
      # First visit on a new install: fill the list before showing it.
      Announcement.sync_from_airtable(force: true)
    else
      # Show what we have right away; refresh from Airtable after the page is sent.
      after_response { Announcement.sync_from_airtable }
    end

    @upcoming = Announcement.upcoming.order(:eventtime).to_a
    @past = Announcement.past.order(eventtime: :desc).limit(12).to_a
    emails = (@upcoming + @past).map { |event| event.audience.to_s.downcase }.select { |e| e.include?('@') }.uniq
    @author_names = User.where('LOWER(email) IN (?)', emails).pluck(:email, :name)
                        .to_h { |email, name| [email.downcase, name] }
  end
end
