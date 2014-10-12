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

    @next_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
                           .setTitle('Next',
                                     forState: UIControlStateNormal)
    @next_button.backgroundColor = UIColor.greenColor
    @next_button.frame = [[600,600],[100,100]]
    @next_button.addTarget(self,
                           action:           'recent_changes_from_anonymous_users',
                           forControlEvents: UIControlEventTouchUpInside)

    @revert_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
                             .setTitle('Revert',
                                       forState: UIControlStateNormal)
    @revert_button.backgroundColor = UIColor.redColor
    @revert_button.frame = [[350,600],[100,100]]
    @revert_button.addTarget(self,
                             action:           'revert_change',
                             forControlEvents: UIControlEventTouchUpInside)
  end

  def recent_changes_from_anonymous_users
    # Crudely assume that all vandals are IP users.
    BW::HTTP.get("#{AppDelegate.api_root}&action=query&list=recentchanges&rcshow=anon&rcprop=title") do |recent_changes|
      if !recent_changes.nil?
        @recent_rev_title = BW::JSON.parse(recent_changes.body)['query']['recentchanges'][0]['title']
      else
        App.alert('Has your Internet connection died? Trying again...')
        recent_changes_from_anonymous_users
      end

      # Get the most recent diff of the revision, based on its title.
      BW::HTTP.get("#{AppDelegate.api_root}&action=query&prop=revisions&titles=#{@recent_rev_title}&rvdiffto=prev") do |diff|
        if !diff.nil?
          diff_content = BW::JSON.parse(diff.body)['query']['pages'].first
          rev_id = diff_content[1]['revisions'][0]['revid']
          old_rev = diff_content[1]['revisions'][0]['diff']['from']
          new_rev = diff_content[1]['revisions'][0]['diff']['to']

          # Hack a URL together to show the mobile website diff, 'cause
          # loadHTMLString refused to work when I got the entire diff
          # out of the API and wanted to display it in a UIWebView.
          url = NSURL.URLWithString("https://en.m.wikipedia.org/w/index.php" \
                                    "?title=#{@recent_rev_title.gsub(' ', '%20').gsub('(', '&#40;').gsub(')', '&#41')}" \
                                    "&curid=#{new_rev}" \
                                    "&diff=#{rev_id}" \
                                    "&oldrev=#{old_rev}"
                                  )
          @diff_view.loadRequest(NSURLRequest.requestWithURL(url))
          self.view.addSubview(@diff_view)
        else
          App.alert('Has your Internet connection died? Trying again...')
          recent_changes_from_anonymous_users
        end

        self.view.addSubview(@next_button)
        self.view.addSubview(@revert_button)
      end

    end
  end

  def revert_change
    BW::HTTP.get("#{AppDelegate.api_root}&action=query&prop=revisions&rvtoken=rollback&titles=#{@recent_rev_title}",
                  { :sessionid => $session_id,
                    :headers => {'Set-Cookie' => $cookie}
                  }
                 ) do |rb_token|
      rollback_token_content = BW::JSON.parse(rb_token.body)['query']['pages'].first
      old_user = rollback_token_content[1]['revisions'][0]['user']
      # The MediaWiki API requires that we encode the + in the token.
      rollback_token = rollback_token_content[1]['revisions'][0]['rollbacktoken'].gsub('+', '%2B')

      BW::HTTP.post("#{AppDelegate.api_root}&action=rollback&user=#{old_user}&title=#{@recent_rev_title}",
                    { payload: { :token => rollback_token },
                      :sessionid => $session_id,
                      :headers => {'Set-Cookie' => $cookie}
                    }
                   ) do |rollback_response|
        if BW::JSON.parse(rollback_response.body)['error']
          App.alert('Something went wrong. Moving on to the next revision...')
        end
      end
    end

    # Call the recent changes method again and get the next
    # revision once reverting and warning is done (or not).
    recent_changes_from_anonymous_users
  end
end
