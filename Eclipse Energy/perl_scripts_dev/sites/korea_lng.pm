=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::korea_lng;
our $DEBUG = 1;
use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use Data::Dumper;
use base qw(Site);

sub key { "korea_lng"; }
sub name { "korea_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://stat.kita.net/statistics/gikz2010d.jsp";

#"http://stat.kita.net/statistics/gikz3010i.jsp"; #"http://global.kita.net/statistics/03/index.jsp";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	$self->{mech}->get($URL);

	print Dumper( $self->{mech}->content()) if $DEBUG;

=pod
#1)	INSTRUCTIONS:
1) Go to http://global.kita.net/statistics/03/index.jsp 
2) You can login with User name: eclipse208 Password: eclipse208.
3) Then Click Statistics from the top menu
4) Opening the page, on the  “Statistics” menu on the left select “Trade by Commodity > All countries”.
5) Fill out HSK as 2711110000. We also select Import, Total and then the latest available year and month. Select Order as Value/Weight, Current/Total as Current Month and unit as: us$1000/kg. Might also be easier to select the number of lines to something like 500. Then click search.
6) Download everything in the table produced. Get rid of commas and have the date in format yyyy-mm-01
7) So the final array should look like: (date,country,type,value) 


=cut

	
	$self->updateDB("eeg.korea_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


