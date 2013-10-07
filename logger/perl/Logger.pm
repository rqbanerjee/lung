package Logger;
use DBI;
use feature ':5.10'; #enable 'say' convenience method
use POSIX qw(strftime);
use YAML qw(LoadFile);
use Sys::Hostname qw(hostname);
use Socket;

# sets PERL5LIB environment variable so that ensembl directories will be able to be accessed from qsub call
$ENV{'PERL5LIB'} = '/usr/local/share/perl/5.12.4:/usr/local/share/perl/5.12.4/ensembl/modules:/usr/local/share/perl/5.12.4/ensembl-compara/modules:/usr/local/share/perl/5.12.4/ensembl-functgenomics/modules:/usr/local/share/perl/5.12.4/ensembl-variation/modules:/usr/local/share/perl/5.12.4/ensembl-external/modules:/usr/share/perl5:/usr/share/perl/5.12.4:/usr/share/perl/5.12';
#print $ENV{'PERL5LIB'};

my $DB_NAME, $DB_HOST, $DB_USER, $DB_PASSWORD, $LOGFILE_PATH, $HOSTNAME, $CALLERS_PID, $HOSTIP, $LOG_ID, $LOG_PRGM;
# sets program location as default qsub script location from ps IF LOG_PRGM variable not passed in
$LOG_PRGM = $0;

# Syntax:
# Logger->log_debug(entity, message)
sub log_debug
{ 
    if ( scalar(@_) > 3 ) {
       $LOG_PRGM = @_[3] ;
    }
    _log('debug', @_[1], @_[2])
}

sub log_info
{  
    if ( scalar(@_) > 3 ) { 
       $LOG_PRGM = @_[3] ; 
    }
    _log('info', @_[1], @_[2])
}

sub log_warn
{
    if ( scalar(@_) > 3 ) {
       $LOG_PRGM = @_[3] ;
    }
    _log('warn', @_[1], @_[2])
}

sub log_error
{
    if ( scalar(@_) > 3 ) {
       $LOG_PRGM = @_[3] ;
    }
    _log('error', @_[1], @_[2])
}

sub log_fatal
{
    if ( scalar(@_) > 3 ) {
       $LOG_PRGM = @_[3] ;
    }
    _log('fatal', @_[1], @_[2])
}

sub log_results
{
    if ( scalar(@_) > 3 ) {
       $LOG_PRGM = @_[3] ;
    }
    _log('results', @_[1], @_[2])
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
    # adds host ip address onto hostname IF doesn't include ip address
    $HOSTIP = "-" . inet_ntoa((gethostbyname(hostname))[4]);
    if ($HOSTNAME =~ /^[a-zA-Z]{4}/) {
           $HOSTNAME .= $HOSTIP;
    }
    #print "$HOSTNAME\n $HOSTIP \n";
    #for the following call, gets PID of calling program 
    $CALLERS_PID = $$;
    #if for some reason the getppid() call fails and returns empty string, put in 0 so SQL INSERT does not fail.
    if ($CALLERS_PID eq '') {
      $CALLERS_PID = 0;
    }
    # assign LOG_ID to be HOST_PPID
    $LOG_ID=$HOSTNAME . "_" . $CALLERS_PID;
    #say "HOSTNAME $HOSTNAME, PID $CALLERS_PID.";
    # assigns LOG_PROGRAM 
    # system("ps -ef | grep $CALLERS_PID");
    #print "\nLog--LOG_PRGM:$LOG_PRGM CALLERS_PID:$CALLERS_PID LOG_ID=$LOG_ID\n";
}

# Private method to log to file
sub _log_to_file
{
    my ($loglevel, $entity, $message) = @_;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $now = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

    open (LOG, ">>$LOGFILE_PATH") or say("Failed to open log file, but will log to db: $!");
    say LOG "$LOG_ID\t$loglevel\t$entity\t$message\t$LOG_PRGM\t$now";
    close(LOG);
}

# Private method for doing the actual work
sub _log
{
    _load_configuration
    my ($loglevel, $entity, $message) = @_;
    say("\n'$LOG_ID' Logging '$message' at loglevel '$loglevel' for entity '$entity' and program '$LOG_PRGM'.");

    _log_to_file($loglevel, $entity, $message);
    $connection_string = "DBI:mysql:database=$DB_NAME;host=$DB_HOST";
    #say "Connection String: $connection_string";

    $dbh = DBI->connect($connection_string, $DB_USER, $DB_PASSWORD)
        or warn "Connection Error: $DBI::errstr\n";

    $fail = 0;
    $errc = '';
    $succ = 0;
    # if logging 'results' expects MySQL statement(s) to be passed in delimited by ';'
    # -- parses these statements and executes them all or until failure -- load log statement will reflect success or failure 
    # of statements and retains statements
    if($loglevel eq 'results'){
      my @sqlcalls = split(';', $LOG_PRGM);
      foreach my $sqlc (@sqlcalls) { 
         # print "\nSQL calls:$sqlc\n";
         if ($fail < 1) {
           $sth = $dbh->prepare($sqlc);
           $sth->execute or do { 
                                 $fail+=1; 
                                 $errc .= "DBD::mysql::st execute failed-See *.out file";
                               };
           $sth->finish;
           if ($fail <  1) {
             $succ += 1;
           }
         }
      }
      if($succ == scalar(@sqlcalls)){
         $message .= "Success ret_code=0";
      } else {
         $message .= "Failure ret_code=$errc";
      }  
    }
    # Adds insert into logs AFTER results have been added IFF results are being added so that 'message' is complete
    $sql = "INSERT INTO logs (log_id, log_level, entity, message, program) VALUES ('$LOG_ID', '$loglevel', '$entity', '$message', '$LOG_PRGM')";

    $sth = $dbh->prepare($sql);
    $sth->execute or die "SQL Error: $DBI::errstr\n";
    $sth->finish;
    $dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}

1;
