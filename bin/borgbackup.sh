#!/bin/sh

# Setting this, so the repo does not need to be given on the commandline:
export BORG_HOST=10.0.0.205
export BORG_REPO=borg@10.0.0.205:/volume1/laptop_backup/borgbackup/

# See the section "Passphrase notes" for more infos.
export BORG_PASSCOMMAND='cat keys/borgkey.txt'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$2" >&2; notify-send -u "$1" "$2" "$3"; }
trap 'info critical "Backup interrupted"; exit 2' INT TERM

# Check if borg host is available at all (i.e. if we are in the local network of Roncalli)
ping -c1 -W1 -q $BORG_HOST
ping_status=$?

if [ ${ping_status} -ne 0 ]; then
    info normal "NAS not available" "Skipping backup because NAS is not available"
    exit 4
fi

info normal "Starting backup" "Borg backup started"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude '/home/*/.cache/*'    \
    --exclude '/var/tmp/*'          \
    --exclude 'pp:/home/daniel/VirtualBox VMs'    \
    --exclude 'pp:/home/daniel/snap'              \
    --exclude 'pp:/home/daniel/downloads'         \
    --exclude 'pp:/home/daniel/.local/share/Trash'\
    --exclude 'pp:/home/daniel/.local/share/Anki2'\
    --exclude 'pp:/home/daniel/Dropbox'           \
    --exclude 'pp:/home/daniel/.rustup'           \
    --exclude 'pp:/home/daniel/.cargo'            \
    --exclude 'pp:/home/daniel/pictures/handy-backup' \
    ::'{hostname}-{now}'            \
    $HOME                               


backup_exit=$?

# exit status 1 means warning
if [ ${backup_exit} -eq 1 ]; then
    info critical "Backup finished with warning"
elif [ ${backup_exit} -ne 0 ]; then
    info critical "Backup failed" "Borg create failed; skipping pruning"
    exit 3
fi


info low "Pruning repository" "Backup done; starting pruning"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  12              \

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info normal "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info critical "Backup and/or Prune finished with warnings"
else
    info critical "Backup and/or Prune finished with errors"
fi

exit ${global_exit}
