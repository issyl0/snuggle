class RecentChangesController < UIViewController

  def viewDidLoad
    # Background colour.
    self.view.backgroundColor = UIColor.whiteColor

    # Logout button.
    logout_button = UIBarButtonItem.alloc.initWithTitle('Logout',
                                                        style:  UIBarButtonItemStylePlain,
                                                        target: AuthenticationController,
                                                        action: 'logout')
    self.navigationItem.rightBarButtonItem = logout_button
  end

end
