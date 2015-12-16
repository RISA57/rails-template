class ErrorsController < ApplicationController
  def routing_error
    raise ActionController::RoutingError.new params[:path]
  end

  def render_error
    exception = env["action_dispatch.exception"]
    status_code = ActionDispatch::ExceptionWrapper.new(env, exception).status_code
    exception_log(status_code, exception)
  end
end
