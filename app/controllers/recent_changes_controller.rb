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

    recent_changes_from_anonymous_users

    @diff_view = UIWebView.alloc.initWithFrame(view.bounds)
  end

  def recent_changes_from_anonymous_users
    # Crudely assume for now that all vandals are IP users.
    BW::HTTP.get("#{AppDelegate.api_root}&action=query&list=recentchanges&rcshow=anon&rcprop=title|id") do |recent_changes|
      recent_rev_title = BW::JSON.parse(recent_changes.body)['query']['recentchanges'][0]['title']

      BW::HTTP.get("#{AppDelegate.api_root}&action=query&prop=revisions&titles=#{recent_rev_title}&rvdiffto=prev") do |diff|
        diff_content = BW::JSON.parse(diff.body)['query']['pages'].first
        rev_id = diff_content[1]['revisions'][0]['revid']
        old_rev = diff_content[1]['revisions'][0]['diff']['from']
        new_rev = diff_content[1]['revisions'][0]['diff']['to']

        # Hack a URL together to show the mobile website diff, 'cause
        # loadHTMLString refused to work when I got the entire diff
        # out of the API and wanted to display it in a UIWebView.
        url = NSURL.URLWithString("https://en.m.wikipedia.org/w/index.php?title=#{recent_rev_title.gsub(' ', '%20')}&curid=#{new_rev}&diff=#{rev_id}&oldrev=#{old_rev}")
        @diff_view.loadRequest(NSURLRequest.requestWithURL(url))
        self.view.addSubview(@diff_view)
      end

    end
  end

end
