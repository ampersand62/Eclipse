=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::canada_monthly_lng;
our $DEBUG = 1;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use Data::Dumper;
use WWW::Mechanize::Firefox;

sub key { "canada_monthly_lng"; }
sub name { "canada_monthly_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.neb-one.gc.ca/CommodityStatistics/GasStatistics.aspx?language=english";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

	# To get round the AJAX in the asp.Net, we need to use Mechanize:Firefox

	$self->{mech} = WWW::Mechanize::Firefox->new();

	$self->{mech}->get($URL);

	my $l = $self->{mech}->xpath('//a[@onclick]', single => 1);
	$self->{mech}->synchronize('DOMFrameContentLoaded', sub {
	    $l->__click()
			   });

	$self->{mech}->select(
	    'ctl00$MainContent$lbReportName',
	    9
	    );

	print Dumper $self->{mech}->content() if $DEBUG;

=pod
#1)	INSTRUCTIONS:
1) Go to http://www.neb-one.gc.ca/CommodityStatistics/GasStatistics.aspx?language=english
2) Click on "Shipment Details - LNG"
3) Choose a From Date as 3 months ago and To Date as the current month
4) Choose activity as imports and format as excel. Then click view.
5) From the excel file, we want all the columns in the table. We dont need the rows with "Total". The month of arrivals should be in the standard date format of YYYY-MM-01.
6) Put the table rows in a multi dim array.

=cut
	my @data;
	
	$self->updateDB("eeg.canada_monthly_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


