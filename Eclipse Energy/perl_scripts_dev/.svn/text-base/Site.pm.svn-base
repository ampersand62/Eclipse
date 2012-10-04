
package Site;

use warnings;
use strict;

use Carp;
use Carp::Assert;
use WWW::Mechanize;
use Number::Format;
use Time::ParseDate;
use DateTime;

use log ();
use eegdbi;
use misc;
use dbihelp;


# Dummy until the switch
sub register {
    my ($cls,$h,$msg) = @_;
    my $obj = $cls->new;
    my $key = $obj->key;
    
    $h->{$key} = [$msg, $obj->name,sub {$obj->invoke(@_);}];
}


# Dummies
sub usesWWW { 0; }
sub usesFTP { 0; }
sub usesXLS { 0; }

sub defaultDateRange { ('yesterday', 'yesterday'); }


sub new {
    my $cls = shift;
    my $self = bless {}, $cls;

    $self->{numformatter} =
	Number::Format->new(
	    -thousands_sep=>'.',
	    -decimal_point=>',');

    $self->{mech} = WWW::Mechanize->new() if $self->usesWWW;
	$self->{ftp} = Net::FTP->new($self->ftp_site) if $self->usesFTP;
	$self->{xls} = Spreadsheet::ParseExcel->new() if $self->usesXLS;

    my ($st,$end) = $self->defaultDateRange;
    $self->{start_date} = DateTime->from_epoch(epoch=>scalar parsedate($st));
    $self->{end_date} = DateTime->from_epoch(epoch=>scalar parsedate($end));

    return $self;
}

sub invoke {

	my $self = shift;

    info("Starting scrape for " . $self->name);
    
    #eval { $self->scrape(@_); };
    $self->scrape(@_);

  #  if($@) {
	#$self->complain("Scrape failed: $@");
	
  #  } else {
    
    #$self->info("Scrape completed successfully.");
    info("Scrape completed successfully.");
	
  #  }
}

sub assertMatch {
    my ($self,$str,$qr) = @_;
    my @list = $str =~ $qr;
    die "Pattern '$str' failed to match regex" unless @list;
    return @list;
}


# Saves the content of the current page and returns the filename
sub saveBackup {
	my $self = shift;
	my $url = $self->{mech}->base;
	my $postfix = ($url =~ m/\.(\w+)$/) ? $1 : "tmp";
	my $fn = "$conf::backup_dir/" . $self->key . "-" . time . ".$postfix";
	$self->{mech}->save_content($fn);
	return $fn;
}

sub pageMatch {
    my ($self,$qr) = @_;
    my @list = $self->{mech}->content =~ $qr;
    die "Page failed to match regex" unless @list;
    return @list;
}

sub updateDB {
	my ($table,$key,$fields,$rows,$name) = @_;
	
	open F, "> $conf::backup_dir/$conf::data_file_name";
	foreach my $t(@$name){
		foreach my $u(@$t){
			print F $u.",";
		}
		print F "\n";	
	}
	close F;
}

sub setIDTable {
    my $self = shift;
    $self->{indexer} = dbihelp->Indexer(@_);
}

sub getID {
    my $self = shift;
    $self->{indexer}->getID(@_);
}


sub clean {
	shift;
	my $g = $_;
	$g = join " ", @_ if @_;
	$g =~ tr/!-~//cd;
	return $g;
}

sub commaNumber {
    shift;
    misc::commaNumber(@_);
}

sub euroNumber {
    my $self = shift;
    my $x = @_ ? shift : $_;
    return $self->{numformatter}->unformat_number($x);
}

sub unformatNumber {
    my $self = shift;
    my $x = @_ ? shift : $_;
    my $d = @_ ? shift : ".";
    $x =~ tr/0-9$d-//cd;
    return $x;
}

sub parseDate {
    shift;
    misc::parseDate(@_);
}

sub info {
    my $self = shift;
    
   # log::info("$_[0]\n");
   log::info($self);
}

sub complain {
    my $self = shift;
    Carp::carp(@_);
    log::info("ERROR:  $_[0]\n       $_[1]\n");
}

sub loadTables {
    my $self = shift;
    $self->{table_index} = tablehelp->load( $self->{mech}->content,
					    clear_html=>1 );
}

sub getTable {
    my $self = shift;

    return $self->{table_index}->popTable(@_);
}

my $a_month = DateTime::Duration->new(months=>1, end_of_month=>'limit');
my $a_year = DateTime::Duration->new(years=>1, end_of_month=>'limit');


sub everyMonth {
    my $self = shift;
    return $self->periodic($a_month, @_);
}

sub everyYear {
	#Runs once for every year between start_date and end_date
    my ($self, $func)  = @_;
    
    my $start = $self->{start_date};

    while($start->year <= $self->{end_date}->year) {
		eval { $func->( $start->year, sprintf("%02d", $start->month),
			   sprintf("%02d", $start->day) ); };
	
		$self->complain("Failed for date " . $start->ymd . ":\n", $@) if($@);
	
		$start += $a_year;
    }
}

sub everyGasYear{
	# Runs onece for every gas year beween start_date and end_date
	my ($self, $func) = @_;

	
    my $start = $self->{start_date};

    while($self->getGasYear($start) <= $self->getGasYear($self->{end_date})) {
		eval { $func->( $start->year, sprintf("%02d", $start->month),
			   sprintf("%02d", $start->day), $start ); };
	
		$self->complain("Failed for date " . $start->ymd . ":\n", $@) if($@);
	
		$start += $a_year;
    }
	
}


sub periodic {
    my ($self,$dur,$func) = @_;

    my $start = $self->{start_date};

    while($start <= $self->{end_date}) {
	eval { $func->( $start->year, sprintf("%02d", $start->month),
		   sprintf("%02d", $start->day) ); };
	
	$self->complain("Failed for date " . $start->ymd . ":\n", $@) if($@);
	
	$start += $dur;
    }
}

sub getGasYear {
#Returns the gasyear that the given date object is in
	my ($self, $date) = @_;
	
	if ($date->month >= 10) {
		return $date->year;
	} else {
		return ($date->year - 1);
	}
	
}



1;

