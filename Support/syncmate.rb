require ENV['TM_SUPPORT_PATH'] + '/lib/textmate'

module SyncMate

  #
  # synchronization
  #
  # *Parameters*:
  # - <tt>method</tt> {Symbol} what to sync [:file|:project]
  #
  def self.sync(method = :file)
    # break out early and do nothing is SyncMate is disabled
    return if not (ENV['TM_SYNCMATE'] || 'true') =~ TRUE_RX
    return if ENV['TM_SYNCMATE_REMOTE_HOST'].nil? or ENV['TM_SYNCMATE_REMOTE_PATH'].nil?
    # set some defaults
    set_defaults
    # break out early if we're not configured to do anything
    return if ENV['TM_SYNCMATE_REMOTE_HOST'].empty? || ENV['TM_SYNCMATE_REMOTE_USER'].empty?
    @destination = File.join(ENV['TM_SYNCMATE_REMOTE_PATH'], (method == :file) ? @relative_file : '')
    @format = (method == :file) ? :text : :html
    # sync
    self.method(METHODS[method]).call
    # post-sync
    if ENV['TM_SYNCMATE_REMOTE_POST_COMMAND']
      puts TEMPLATES[@format].gsub(/\{BEGIN\}/, "running remote command...#{NL[@format]}\$ #{ENV['TM_SYNCMATE_REMOTE_POST_COMMAND']}").gsub(/\{BODY\}/, %x(#{commands(:post)})).gsub(/\{END\}/, 'remote command completed!')
    end

  end

private
  # methods
  METHODS = {
    :file     => :sync_file,
    :project  => :sync_project
  }
  # defaults
  DEFAULTS = [
    { :key => 'TM_SYNCMATE_REMOTE_USER',    :default => %x(id -un).strip },
    { :key => 'TM_SYNCMATE_REMOTE_PORT',    :default => '22' },
    { :key => 'TM_SYNCMATE_REMOTE_PATH',    :default => ENV['TM_PROJECT_DIRECTORY'] },
    { :key => 'TM_SYNCMATE_LOCAL_USER',     :default => %x(id -un).strip },
    { :key => 'TM_SYNCMATE_RSYNC_OPTIONS',  :default => '--exclude=.git --exclude=.svn --cvs-exclude' }
  ]
  # templates
  TEMPLATES = {
    :text => "{BEGIN}\n{BODY}\n{END}",
    :html => "{BEGIN}<pre>{BODY}</pre>{END}"
  }
  NL = {
    :text => "\n",
    :html => "<br/>"
  }
  # some regex
  TRUE_RX   = /^(?:true|yes|1)$/i
  FALSE_RX  = /^(?:false|no|0)$/i

  def self.sync_file
    puts "syncing... #{@relative_file} to #{ENV['TM_SYNCMATE_REMOTE_HOST']}"
    # execute the sync command and throw an exception if there are errors
    throw_exception %x(#{commands(:scp)})
    puts "synced to: #{@destination}"
  end

  def self.sync_project
    puts "syncing... #{ENV['TM_PROJECT_DIRECTORY']}/* to #{ENV['TM_SYNCMATE_REMOTE_HOST']}"
    puts "<pre>"
    puts %x(#{commands(:rsync)})
    puts "</pre>"
    puts "synced to: #{@destination}"
  end

  def self.commands(type = :scp)
    cmds = []

    # if a local user is set, piggy back on their SSH_AUTH_SOCK
    if not type == :post and not ENV['TM_SYNCMATE_LOCAL_USER'] =~ FALSE_RX
      cmds.push "export SSH_AUTH_SOCK=$(find /tmp/launch-*/Listeners -user \"#{ENV['TM_SYNCMATE_LOCAL_USER']}\" -type s | head -1 )"
    end

    case type
    when :post
      cmds.push "ssh -f -p \"#{ENV['TM_SYNCMATE_REMOTE_PORT']}\" \"#{ENV['TM_SYNCMATE_REMOTE_USER']}@#{ENV['TM_SYNCMATE_REMOTE_HOST']}\" -- \"cd '#{ENV['TM_SYNCMATE_REMOTE_PATH']}'"
      cmds.push "#{ENV['TM_SYNCMATE_REMOTE_POST_COMMAND']} 2>&1"
    when :scp
      cmds.push "scp -P \"#{ENV['TM_SYNCMATE_REMOTE_PORT']}\" \"#{ENV['TM_FILEPATH']}\" \"#{ENV['TM_SYNCMATE_REMOTE_USER']}@#{ENV['TM_SYNCMATE_REMOTE_HOST']}:'#{@destination}'\" 2>&1"
    when :rsync
      rsync = "rsync -v -zar #{ENV['TM_SYNCMATE_RSYNC_OPTIONS']} -e "
      rsync << "\"ssh -p #{ENV['TM_SYNCMATE_REMOTE_PORT']}\" \"#{ENV['TM_PROJECT_DIRECTORY']}/\" \"#{ENV['TM_SYNCMATE_REMOTE_USER']}@#{ENV['TM_SYNCMATE_REMOTE_HOST']}:'#{ENV['TM_SYNCMATE_REMOTE_PATH']}/'\" 2>&1 "
      rsync << "| grep -v 'bind: Address already in use' | grep -v 'channel_setup_fwd_listener: cannot listen to port:' | grep -v 'Could not request local forwarding.'"
      cmds.push(rsync)
    end

    return cmds.join(';')
  end

  def self.set_defaults
    DEFAULTS.each do |default|
      ENV[default[:key]] ||= default[:default]
    end
    ENV['TM_SYNCMATE_REMOTE_PATH'] = ENV['TM_SYNCMATE_REMOTE_PATH'].gsub(/\{TM_SYNCMATE_REMOTE_USER\}/, ENV['TM_SYNCMATE_REMOTE_USER'])
    ENV['TM_SYNCMATE_REMOTE_HOST'] = ENV['TM_SYNCMATE_REMOTE_HOST'].gsub(/\{TM_SYNCMATE_REMOTE_USER\}/, ENV['TM_SYNCMATE_REMOTE_USER'])
    @relative_file = ENV['TM_FILEPATH'].gsub(ENV['TM_PROJECT_DIRECTORY'] + '/', '')
  end

  #
  # throw a message in the TextMate tooltip and about if the condition is met
  #
  # *Parameters*:
  # - <tt>message</tt> {String} the exception to throw
  # - <tt>condition</tt> {Boolean} the condition to test against
  #
  def self.throw_exception(message, condition = true)
    # indent the message
    message = (message || '').gsub(/\n/, '  \n')
    TextMate.exit_show_tool_tip "SyncMate Exception:\n  #{message}" if condition and not message.empty?
  end

end
