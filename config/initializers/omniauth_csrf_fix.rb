# Fix for OmniAuth v2 + Rails 7+ per-form CSRF tokens incompatibility.
#
# Rails 7+ defaults to per_form_csrf_tokens = true, which means each form gets a unique
# CSRF token and no global _csrf_token is stored in the session. OmniAuth v2's
# AuthenticityTokenProtection middleware expects a global session['_csrf_token'] to exist
# and will reject POST requests to /auth/:provider if the session lacks it.
#
# Solution: Disable per_form_csrf_tokens so Rails stores a single global CSRF token in
# the session (the pre-Rails-7 behavior). This is safe and maintains CSRF protection.

Rails.application.config.action_controller.per_form_csrf_tokens = false
