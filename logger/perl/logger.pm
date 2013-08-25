package Logger;
use DBI;

my $DB_NAME = 'lung';
my $DB_HOST = 'localhost';
my $DB_USER = 'lung-logger';
my $DB_PASSWORD = 'changeme';

sub log_debug
{
    _log('debug', @_[1])
}

sub log_info
{
    _log('info', @_[1])
}

sub log_warn
{
    _log('warn', @_[1])
}

sub log_error
{
    _log('error', @_[1])
}

sub log_fatal
{
    _log('fatal', @_[1])
}

sub new
{
    printf("Will log into database '$DB_NAME' on '$DB_HOST' as '$DB_USER'.\n\n");
    # Print out DB parameters
}

# Private method for doing the actual work
sub _log
{
    my ($loglevel, $message) = @_;
    printf("Logging '$message' at loglevel '$loglevel'.\n");

    $dbh = DBI->connect("DBI:mysql:$DB_NAME@$DB_HOST", $DB_USER, $DB_PASSWORD)
        or die "Connection Error: $DBI::errstr\n";

    $sql = "INSERT INTO logs (log_level, message) VALUES ('$loglevel', '$message')";
    #printf("SQL: $sql\n\n");

    $sth = $dbh->prepare($sql);
    $sth->execute or die "SQL Error: $DBI::errstr\n";
}

1;