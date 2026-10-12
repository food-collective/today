class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
    redirect_to tasks_path if current_user && !session_expired?
  end

  def create
    email = params.dig(:session, :email).to_s.strip.downcase
    user = find_active_member(email)

    if user.nil? && email.present?
      # Not in the app yet. New members are added in Airtable, so check there now.
      User.sync_from_airtable(force: true)
      user = find_active_member(email)
    end

    if user
      reset_session
      login user
      session[:expires_at] = 12.hours.from_now.to_i unless params.dig(:session, :remember) == '1'
      cookies.delete(:checking_as)
      # Refresh the member list in the background (at most every 12 hours).
      after_response { User.sync_from_airtable }
      redirect_to tasks_path
    else
      flash[:danger] = "We couldn't find an active member with that email. Check the spelling, or ask a coordinator to add you in Airtable."
      redirect_to login_path
    end
  end

  def destroy
    logout
    reset_session
    cookies.delete(:checking_as)
    flash[:success] = 'You’re logged out. See you next shift!'
    redirect_to login_path
  end

  private

  def find_active_member(email)
    return nil if email.blank?

    User.where('LOWER(email) = ?', email).where(active: true).first
  end
end
