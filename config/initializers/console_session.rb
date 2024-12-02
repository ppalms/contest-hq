if Rails.env.development?
  module ConsoleMethods
    def setup_session
      test_user = User.find_by!(email: "johndoe@school.org")
      test_session = Session.create(user: test_user)
      Current.session = test_session
    end
  end

  Rails.application.console do
    include ConsoleMethods
    puts "Type 'setup_session' to create a test session"
  end
end
