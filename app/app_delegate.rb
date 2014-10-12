class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    controller = AuthenticationController.alloc.initWithNibName(nil, bundle:nil)
    @window.rootViewController = UINavigationController.alloc.initWithRootViewController(controller)
    @window.makeKeyAndVisible
  end

  def self.api_root
    'http://en.wikipedia.org/w/api.php?format=json'
  end
end
