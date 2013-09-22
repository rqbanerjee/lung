package Logger;
use DBI;
use feature ':5.10'; #enable 'say' convenience method
use POSIX qw(strftime);
use YAML qw(LoadFile);
use Sys::Hostname qw(hostname);

my $DB_NAME, $DB_HOST, $DB_USER, $DB_PASSWORD, $LOGFILE_PATH, $HOSTNAME, $CALLERS_PID;

# Syntax:
# Logger->log_debug(entity, message)
sub log_debug
{
    _log('debug', @_[1], @_[2])
}

sub log_info
{
    _log('info', @_[1], @_[2])
}

sub log_warn
{
    _log('warn', @_[1], @_[2])
}

sub log_error
{
    _log('error', @_[1], @_[2])
}

sub log_fatal
{
    _log('fatal', @_[1], @_[2])
}

sub new
{
    say("Will log into database '$DB_NAME' on '$DB_HOST' as '$DB_USER'.\n");
    # Print out DB parameters
}

# Private method to load constants from file
sub _load_configuration
{
    # load YAML file into perl hash ref?
    my $config = LoadFile("/Projects/Common/scripts/perl/config.yml");
    ($DB_NAME, $DB_HOST, $DB_USER, $DB_PASSWORD, $LOGFILE_PATH) =
        ($config->{DB_NAME}, $config->{DB_HOST}, $config->{DB_USER}, $config->{DB_PASSWORD}, $config->{LOGFILE_PATH});
    $HOSTNAME = hostname;

    #for the following call, calling $PID always returned ''. TODO, figure out why and which PID Jennifer wants
    $CALLERS_PID = getppid();
    #if for some reason the getppid() call fails and returns empty string, put in 0 so SQL INSERT does not fail.
    if ($CALLERS_PID eq '') {
      $CALLERS_PID = 0;
    }
    #say "HOSTNAME $HOSTNAME, PID $CALLERS_PID.";
}

# Private method to log to file
sub _log_to_file
{
    my ($loglevel, $entity, $message) = @_;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $now = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

    open (LOG, ">>$LOGFILE_PATH") or say("Failed to open log file, but will log to db: $!");
    say LOG "$loglevel\t - $now [$entity] - $message";
    close(LOG);
}

# Private method for doing the actual work
sub _log
{
    _load_configuration
    my ($loglevel, $entity, $message) = @_;
    say("Logging '$message' at loglevel '$loglevel' for entity '$entity'.");

    _log_to_file($loglevel, $entity, $message);
    $connection_string = "DBI:mysql:database=$DB_NAME;host=$DB_HOST";
    #say "Connection String: $connection_string";

    $dbh = DBI->connect($connection_string, $DB_USER, $DB_PASSWORD)
        or warn "Connection Error: $DBI::errstr\n";

    $sql = "INSERT INTO logs (log_level, entity, message, hostname, pid) VALUES ('$loglevel', '$entity', '$message', '$HOSTNAME', '$CALLERS_PID')";
    #say("SQL: $sql\n");

    $sth = $dbh->prepare($sql);
    $sth->execute or die "SQL Error: $DBI::errstr\n";
    $dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}

1;
