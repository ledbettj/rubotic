class GitPlugin < Rubotic::Plugin
  describe "Allow updating and restarting from git"

  command '!update' do
    describe 'update to the latest git commit on master'

    run do |event|
      update_self(event)
    end
  end

  command '?update' do
    describe 'check if any updates are available'

    run do |event|
      check_update(event)
    end
  end

  private

  def fetch
    `git fetch`
  end

  def missing_commits
    `git log HEAD..origin/master --pretty="tformat:%h: %s%d [%an]" --graph --date=short`
  end

  def do_update!
    root = File.expand_path('../../../', __FILE__)
    Dir.chdir(root)
    bot.quit("Rubotic update in progress...")
    `git merge origin/master`
    `bundle install`
    `bundle exec bin/rubotic`
    exec 'bundle exec bin/rubotic'
  end

  def update_self(event)
    fetch
    if missing_commits.split("\n").length > 0
      do_update!
    else
      respond_to(event, "No updates found")
    end
  end

  def check_update(event)
    fetch
    if (commits = missing_commits.split("\n")).length > 0
      commits.map { |c| respond_to(event, c) }
    else
      respond_to(event, "No updates found")
    end
  end
end
