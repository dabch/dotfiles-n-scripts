# dotfiles-n-scripts

Collection of some configuration files and selfmade scripts making my Linux life easier. 

Currently interesting stuff:
- `bin/borgbackup.sh`: Script that triggers [Borgbackup](https://borgbackup.readthedocs.io) to create a new backup if my NAS is available and manage old backups. Basically just calls Borg and notifies me via `notify-send`
- `.config/anacrontab`: Anacron entry to trigger my backup script daily while writing the output to a logfile 
