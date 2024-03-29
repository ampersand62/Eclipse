=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::ewe;
our $DEBUG = 1;
use Mozilla::CA; # Needed to fetch https frame content

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

use Encode;

sub key { "ewe"; }
sub name { "ewe";}
sub usesWWW { 1; }
#

#URL of website to scrape
#my $URL = "http://www.ewe-gasspeicher.de/english/transparency.php";
# The Data we require is actually in an iframe
my $URL = "https://b2b.ewe-gasspeicher.de/GasXLastfluss/";

sub scrape {

    my ($year, $month, $day) = Today();

    # We are interested in seven days ago

    my ($yy, $mm, $dd) = Add_Delta_Days( $year, $month, $day, -7);
    
    #has the mechanize object. 
    my $self = shift;
    
    $self->{mech}->get($URL);

    $self->{mech}->field( 'ASPxStartDate', sprintf("%02d.%02d.%04d", $dd, $mm, $yy));
    $self ->{mech}->field( 'ASPxNetzPunkt', decode_utf8("Gasspeicher R\x{C3BC}dersdorf H-Gas"));

    $self->{mech}->submit();
			  

    print $self->{mech}->content();
    
=pod
#1)	INSTRUCTIONS:
1) go to http://www.ewe-gasspeicher.de/english/transparency.php
2) We want last 7 days each time for each Standort (point)
3) You can grab the html table or CSV. Please do a header check to check the headers are in the positions we expect them to be in. You can use Carp::Assert.
4) From the table, we'd like all the colums. Remove decimals and treat commas as decimals.
5) So the final array would look like: <date,point_name,injection,withdrawal,stock_level>
=cut
	my @data;
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


