module ControllerMacros
  # Example
  # def login_user
  #   before(:each) do
  #     @request.env['devise.mapping'] = Devise.mappings[:user]
  #     @user = FactoryGirl.create(:user)
  #     sign_in @user
  #   end
  # end
end


RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.extend ControllerMacros, type: :controller
end
