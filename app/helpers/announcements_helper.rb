module AnnouncementsHelper
  PLACEHOLDER_LOCATIONS = ['tba', 'tbd', 'check slack', 'on campus tba', 'tba on campus'].freeze

  def event_time_label(event)
    return 'Time to be announced' unless event.eventtime

    time = event.eventtime
    time.min.zero? ? time.strftime('%-l %p') : time.strftime('%-l:%M %p')
  end

  # A Google Maps link for real addresses; plain text for "TBA" and the like.
  def event_location(event)
    location = event.location.to_s.strip
    return nil if location.empty?
    return location if PLACEHOLDER_LOCATIONS.include?(location.downcase) || location.start_with?('http')

    link_to location, "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(location)}",
            target: '_blank', rel: 'noopener'
  end

  # Shows a member's name when the poster's email matches a member.
  def event_author(event, names = {})
    author = event.audience.to_s
    return 'BSFC' if author.blank? || author == 'BSFC'

    names[author.downcase].presence || author
  end
end
