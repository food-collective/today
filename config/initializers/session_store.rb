# Logins last up to 30 days on a device ("Keep me signed in"); without it,
# the app ends the login after 12 hours (see ApplicationController).
Rails.application.config.session_store :cookie_store, key: '_bfc_today_session', expire_after: 30.days
