=pod
Description: Entsoe Web Scrape. As described in comments, except I extracted 
the data from a js function rather than saving it as an Excel file. Happy 
that the data is the same.
Note the use of $DEBUG as usual to determine behaviour
The "hour" parameter is presented as a simple integer from 1 .. 24; it could
easily be formateed to be 01:00 etc, but that would probably add further 
processing necessary further down the line to no real advantage.
Created by: Andy Holyer
Date: 13/08/2012
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::entsoe_consumption;

use File::Temp;
our $DEBUG = 1;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "entsoe_consumption"; }
sub name { "entsoe_consumption";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "https://www.entsoe.eu/db-query/consumption/mhlv-all-countries-for-a-specific-month/";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	my ($year, $month, $day) = Today();

	for my $i ( 1 .. 3) {
	    $month--;
	    if ($month < 1) {
		$month = 12;
		$year--
	    }
	    $self->{mech}->get($URL);
	    
	    $self->{mech}->select('opt_Month', $month);
	    $self->{mech}->select('opt_Year', $year);
	    $self->{mech}->select('opt_Response', 1);

	    $self->{mech}->submit();

	    # The data is stored in a javascript function included inline:
	    # Luckily the actual data is pretty easy to extract
	    my $content = File::Temp->new();

	    print $content $self->{mech}->content();

	    $content->seek(0,0);
	    my $data;
	    while (<$content>) {
		if (/var myData = \[(.*)\]/) {
		    $data = $1;
		    last;
		}
	    }
	    

	    $data =~ s/\[(.*)\]/$1/;

	    my @lines = split /\],\[/, $data;

	    foreach my $line (@lines) {
		my ($country, $date, @hours) = split /,/, $line;

		my $hour = 1;

		foreach my $value (@hours) {
		    print "$date: $hour, $country, $value\n" if $DEBUG;
		    push @data, [$date, $hour, $country, $value] unless $DEBUG;
		    $hour++;
		}
	    }
	}

=pod
#1)	INSTRUCTIONS:
1) go to https://www.entsoe.eu/db-query/consumption/mhlv-all-countries-for-a-specific-month/
2) We want to download the last 3 months files each time in XLS format
3) We'd like the 2nd table in the file (the big one). The final array should look like: <date,hour,country,value>.


=cut
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


