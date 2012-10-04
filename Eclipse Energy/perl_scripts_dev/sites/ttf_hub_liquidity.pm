=pod
Description: Scrape TTF Excel file
Created by: Andy Holyer
Date: 20/04/12
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::ttf_hub_liquidity;

our $DEBUG = 1;
use Spreadsheet::ParseExcel;
use File::Temp;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "ttf_hub_liquidity"; }
sub name { "ttf_hub_liquidity";}
sub usesWWW { 1; }
#

# This script sometimes spells "Oct" as "Okt", so a workaround...
$monthToNum{'Okt'} = 10;

#URL of website to scrape
my $URL = "http://www.gastransportservices.nl/en/transportinformation/ttf-volume-development";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

	my @data;

	$self->{mech}->get($URL);
	
	$self->{mech}->follow_link(
	    text_regex => qr/Weekpublicatie TTF/
	    );

	my $excel = File::Temp->new(
	    suffix => '.xls'
	    );

	print $excel $self->{mech}->content();

	my $parser = Spreadsheet::ParseExcel->new();

	my $wb = $parser->Parse($excel);

	my $ws = $wb->worksheet(0);

	my ($row_min, $row_max) = $ws->row_range();

	for my $row ($row_min .. $row_max) {
	    # Date - Col 0, Traded = 1, Net = 2
	    my $cell = $ws->get_cell($row, 0);
	    next unless $cell 
		&& 
		$cell->value() =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Okt|Nov|Dec) (\d\d)/;

	    my ($mon, $year) = ($1, $2);

	    my $date = sprintf("%4d-%02d-01", $year+2000, $monthToNum{$mon});

	    my $traded = $ws->get_cell($row, 1)->unformatted();
	    my $net = $ws->get_cell($row, 2)->unformatted();

	    print "$date: $traded, $net\n" if $DEBUG;

	    push @data, [$date, $traded, $net];
	}
=pod
#1)	INSTRUCTIONS:
1) - Go to http://www.gastransportservices.nl/en/transportinformation/ttf-volume-development
2) Select the download at the bottom of the page
3) Pick up "Traded volume" and "Net volume" data
4) Data should be in format YYYY-MM-01. final array should look like: <date,traded,net>

=cut
	
	$self->updateDB("eeg.ttf_hub_liquidity_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;

