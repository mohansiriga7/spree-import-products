module AuthenticationHelpers
  def sign_in_as!(user)
    # visit '/login'
    visit spree.admin_login_path # No Route /admin wtf????
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'secret'
    click_button 'Login'
  end
end

RSpec.configure do |c|
  c.include AuthenticationHelpers, type: :request
end
