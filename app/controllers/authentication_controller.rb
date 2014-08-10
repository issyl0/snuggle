class AuthenticationController < UIViewController

  def viewDidLoad
    # Background colour.
    self.view.backgroundColor = UIColor.whiteColor

    # Login button.
    login_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
                           .setTitle('Login',
                                     forState: UIControlStateNormal)
    login_button.frame = [[100,100],[100,100]]
    login_button.addTarget(self,
                           action:           'login',
                           forControlEvents: UIControlEventTouchUpInside)
    self.view.addSubview(login_button)

    # Logout button.
    logout_button = UIBarButtonItem.alloc.initWithTitle('Logout',
                                                        style:  UIBarButtonItemStylePlain,
                                                        target: self,
                                                        action: 'logout')
    self.navigationItem.rightBarButtonItem = logout_button

    # Username textfield.
    username_textfield = UITextField.alloc.initWithFrame([[100,60],[100,60]])
    username_textfield.placeholder = 'username'
    username_textfield.textColor = UIColor.blackColor
    @username = username_textfield
    self.view.addSubview(username_textfield)

    # Password textfield
    password_textfield = UITextField.alloc.initWithFrame([[100,80],[100,80]])
    password_textfield.placeholder = 'password'
    password_textfield.textColor = UIColor.blackColor
    @password = password_textfield
    self.view.addSubview(password_textfield)
  end

  def login
    login_query = "#{AppDelegate.api_root}&action=login&lgname=#{@username}&lgpassword=#{@password}"
    rollback_query = "#{AppDelegate.api_root}&action=query&meta=userinfo&uiprop=rights"
    BW::HTTP.post(login_query) do |basic_auth|
      basic_auth_body = BW::JSON.parse(basic_auth.body)

      if basic_auth.ok?
        cookie = basic_auth.headers['Set-Cookie']
        if basic_auth_body['login']['result'] == 'NeedToken'
          BW::HTTP.post("#{login_query}&lgtoken=#{basic_auth_body['login']['token']}", { :cookie => cookie, :headers => {'Set-Cookie' => cookie} }) do |token_auth|
            if token_auth.ok?
              App.alert('Logged in.')
            else
              App.alert('Authentication failed.')
            end
          end
        else
          App.alert('Something went wrong.')
        end
      end
    end 
  end

  def logout
    BW::HTTP.post(AppDelegate.api_root + '&action=logout') do |r|
      App.alert('Logged out') if r.ok?
    end
  end

end
