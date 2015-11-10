## Demo deploy tool

### Assumptions
* You have you aws credentials set up in ~/.aws/credentials
* Ruby and Rails installs
* Have github oauth token set up as env var ie application.yml OAUTHTOKEN: my_github_oauth_token


### Run
```
git clone git@github.com:david-richey/deployapp.git
cd deployapp
bundle install
# Process to start

# 1. boot rails server
rails s
# 2. ngrok for hooks from web
nrgok 3000
# 3. start sidekiq
bundle exec sidekiq