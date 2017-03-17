class Superadmin::SuperadminController < ActionController::Base
  #include SslRequirement
  before_filter :authenticate

  rescue_from StandardError, with: :rescue_from_superadmin_error

  def self.ssl_required(*splat)
    if Rails.env.production? || Rails.env.staging?
      force_ssl only: splat
    end
  end

  def self.ssl_allowed(*splat)
    # noop
  end

  protected

  def authenticate
    return true if Rails.env.development? || authenticated?(CartoDB.extract_subdomain(request)) && current_user.admin
    authenticate_or_request_with_http_basic do |username, password|
      username == Cartodb.config[:superadmin]["username"] && password == Cartodb.config[:superadmin]["password"]
    end
  end

  def current_user
    super(CartoDB.extract_subdomain(request))
  end

  private

  def rescue_from_superadmin_error(error)
    CartoDB::Logger.error(exception: error)
    render(json: { errors: { message: error.inspect, backtrace: error.backtrace.inspect } }, status: 500)
  end
end
