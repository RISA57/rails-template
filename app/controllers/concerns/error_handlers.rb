module ErrorHandlers
  extend ActiveSupport::Concern

  included do
    unless Rails.application.config.consider_all_requests_local
      rescue_from Exception, with: :render_500
      rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound, with: :render_404
      rescue_from ActionController::InvalidAuthenticityToken, with: :render_422
    end
  end

  private

  def exception_log(code, exception)
    if exception
      logger.info "Rendering #{code} with exception: #{exception.message}"
    end

    render template: "shared/errors/error_#{code}.html.erb", status: code, content_type: 'text/html'
  end

  def render_404(exception=nil)
    exception_log(404, exception)
  end

  def render_422(exception=nil)
    exception_log(422, exception)
  end

  def render_500(exception=nil)
    exception_log(500, exception)
  end
end
