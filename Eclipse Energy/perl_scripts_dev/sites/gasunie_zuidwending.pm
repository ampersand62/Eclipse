=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::gasunie_zuidwending;
our $DEBUG = 1;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "gasunie_zuidwending"; }
sub name { "gasunie_zuidwending";}
sub usesWWW { 1; }
#
use File::Temp;

#URL of website to scrape
my $URL = "http://www.gasuniezuidwending.nl/flow-and-volume-information/flow-informatie";
my $STORAGE = "http://www.gasuniezuidwending.nl/flow-and-volume-information/storage-informatie";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	my ($y, $m, $d) = Today();
	my ($yy, $mm, $dd) = Add_Delta_Days($y, $m, $d, -7);


	$self->{mech}->get($URL);

	$self->{mech}->form_id('parameters');

	$self->{mech}->set_fields(
	    startdate_Day => sprintf("%02d", $dd),
	    startdate_Month => sprintf("%02d", $mm),
	    startdate_Year => $yy,
	    enddate_Day => sprintf("%02d", $d),
	    enddate_Month => sprintf("%02d", $m),
	    enddate_Year => $y,
	    unit => 'kWh',
	    view => 'table'
	    );

	$self->{mech}->submit();

	my $temp = File::Temp->new();
	print $temp $self->{mech}->content();
	$temp->seek( 0, 0);
	
	# Scan forward to the table we're after
	while (<$temp>) {
	    last if m/<tbody>/;
	}

	while (<$temp>) {
	    # Set of <tr>s ....
	    last unless m/<tr>/;

	    # Consisting of date, in, out, physflow

	    $_ = <$temp>;
	    m/(\d\d)-(\d\d)-(\d\d\d\d)/;
	    my $date = sprintf ("%04d-%02d-%02d", $3, $2, $1);

	    $_ = <$temp>;
	    m/([0-9,-]+)/;
	    my $in = $1;
	    $in =~ s/,//g;

	    $_ = <$temp>;
	    m/([0-9,-]+)/;
	    my $out = $1;
	    $out =~ s/,//g;

	    $_ = <$temp>;
	    m/([0-9,-]+)/;
	    my $physflow = $1;
	    $physflow =~ s/,//g;

	    print "$date: $in, $out, $physflow\n" if $DEBUG;

	    push @data, [$date, $in, $out, $physflow] unless $DEBUG;
	    # Skip the </tr>

	    $_ = <$temp>;
	}

	# Once more, with feeling!

	$self->{mech}->get($STORAGE);

	$self->{mech}->form_id('parameters');

	$self->{mech}->set_fields(
	    startdate_Day => sprintf("%02d", $dd),
	    startdate_Month => sprintf("%02d", $mm),
	    startdate_Year => $yy,
	    enddate_Day => sprintf("%02d", $d),
	    enddate_Month => sprintf("%02d", $m),
	    enddate_Year => $y,
	    unit => 'kWh',
	    view => 'table'
	    );

	$self->{mech}->submit();

	my $t2 = File::Temp->new();
	print $t2 $self->{mech}->content();
	$t2->seek( 0, 0);
	
	# Scan forward to the table we're after
	while (<$t2>) {
	    last if m/<tbody>/;
	}

	while (<$t2>) {
	    # Set of <tr>s ....
	    last unless m/<tr>/;

	    # This one has date, storage, percent (last one we discard)

	    $_ = <$t2>;
	    m/(\d\d)-(\d\d)-(\d\d\d\d)/;
	    my $date = sprintf ("%04d-%02d-%02d", $3, $2, $1);

	    $_ = <$t2>;
	    m/([0-9,-]+)/;
	    my $storage = $1;
	    $storage =~ s/,//g;

	    $_ = <$t2>;

	    print "$date: $storage\n" if $DEBUG;

	    push @data, [$date, $storage] unless $DEBUG;
	    # Skip the </tr>

	    $_ = <$t2>;
	}
	    
=pod
#1)	INSTRUCTIONS:
1) go to http://www.gasuniezuidwending.nl/flow-and-volume-information/flow-informatie
2) put date from as today-7, end date as today -1. unit kwh. view as table, then apply.
3) we want all the data in the resulting table. date in yyyy-mm-dd. so the final array: <date,in,out,physflow>

1) go to http://www.gasuniezuidwending.nl/flow-and-volume-information/storage-informatie
2) follow the steps as in 2. final array should look like: <date,gas_in_storage>

=cut

	
	$self->updateDB("eeg.gasunie_zuidwending_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


