# SyncMate

Easily keep file changes synchronized with a remote destination with TextMate.

## Installation

```sh
mkdir -p ~/Library/Application\ Support/Avian/Bundles
cd ~/Library/Application\ Support/Avian/Bundles
git clone git://github.com/eoneill/SyncMate.tmbundle.git
```

## Usage

* `⌘S` - sync file on save (actually bound to save via `callback.document.did-save`, not specifically the key bind)
* `⌘⇧P` - sync the entire project

## Configuration

Make it work the way you do. Set these configuration options in your project `.tm_properties`:

* `TM_SYNCMATE` - if set to `false`, disables SyncMate (default: `true`)
* `TM_SYNCMATE_REMOTE_HOST` - the remote host to sync to
* `TM_SYNCMATE_REMOTE_PATH` - the remote path to sync to

### Advanced Configurations

* `TM_SYNCMATE_REMOTE_PORT` - the remote port (default: `22`)
* `TM_SYNCMATE_REMOTE_USER` - the remote user account to use (default current logged in user)
* `TM_SYNCMATE_LOCAL_USER` - the local user account to use (default current logged in user)
* `TM_SYNCMATE_RSYNC_OPTIONS` - the options you want passed along to rsync (default: `--exclude=.git --exclude=.svn --cvs-exclude`)
* `TM_SYNCMATE_REMOTE_POST_COMMAND` - a command to run after syncing (e.g. `make && make install`)

## Inspiration

... and borrowed code :)

* https://github.com/davidolrik/SynchronizeRemoteDirectory-rsync-ssh.tmbundle
