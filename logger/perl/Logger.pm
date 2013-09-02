package Logger;
use DBI;
use feature ':5.10'; #enable 'say' convenience method
use POSIX qw(strftime);

my $DB_NAME = 'lung';
my $DB_HOST = 'localhost';
my $DB_USER = 'lung-logger';
my $DB_PASSWORD = 'changeme';
my $LOGFILE_PATH = '/tmp/temp_logs/log.txt';

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
    my ($loglevel, $entity, $message) = @_;
    say("Logging '$message' at loglevel '$loglevel' for entity '$entity'.");

    _log_to_file($loglevel, $entity, $message);
    $dbh = DBI->connect("DBI:mysql:$DB_NAME@$DB_HOST", $DB_USER, $DB_PASSWORD)
        or die "Connection Error: $DBI::errstr\n";

    $sql = "INSERT INTO logs (log_level, entity, message) VALUES ('$loglevel', '$entity','$message')";
    #say("SQL: $sql");

    $sth = $dbh->prepare($sql);
    $sth->execute or die "SQL Error: $DBI::errstr\n";
    $dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}

1;
