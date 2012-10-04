=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::grtgaz_daily;
our $DEBUG = 1;

use Data::Dumper;
use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "grtgaz_daily"; }
sub name { "grtgaz_daily";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "https://www.grtgaz-d.de/portal/servlet/OpenPortal";


sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

	$self->{mech}->get($URL);
	$self->{mech}->submit();

	print $self->{mech}->content() if $DEBUG;

=pod
#1)	INSTRUCTIONS:
1) On the menu on the left hand side select public reports, then select  each of the border points. 
2) There is a drop down menu called "Station schedule CSV" for the hourly data. You can then export to CSV
3) Have a loop which goes and collect the last 7 days from the CSV (including today)
4) Date should be in YYYY-MM-DD. So the final array will look like: <date_time,point_name,station_schedule>.


=cut
	my @data;
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


