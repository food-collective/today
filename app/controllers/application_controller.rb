class ApplicationController < ActionController::Base
  include SessionsHelper

  before_action :require_login
  helper_method :acting_name, :open_task_count, :upcoming_event_count

  private

  def require_login
    return if current_user && !session_expired?

    logout
    flash[:danger] = 'Please log in to continue.'
    redirect_to root_path
  end

  # "Keep me signed in" off: the login lasts 12 hours. On: 30 days.
  def session_expired?
    session[:expires_at].present? && Time.current.to_i > session[:expires_at].to_i
  end

  # The name credited when someone adds or checks off a task. On a shared
  # account (like the store's), people can pick their own name for the shift.
  def acting_name
    cookies[:checking_as].presence || current_user&.name
  end

  def open_task_count
    @open_task_count ||= Task.visible_to(current_user).where(completed: false).count
  end

  def upcoming_event_count
    @upcoming_event_count ||= Announcement.upcoming.count
  end

  # Runs slow work (like refreshing from Airtable) after the page has been
  # sent, when the web server supports it (Puma does). Otherwise runs it now.
  def after_response(&block)
    callbacks = request.env['rack.after_reply']
    if callbacks
      callbacks << -> { Rails.application.executor.wrap { safely(&block) } }
    else
      safely(&block)
    end
  end

  def safely
    yield
  rescue StandardError => e
    Rails.logger.error("[background] #{e.class}: #{e.message}")
  end
end
