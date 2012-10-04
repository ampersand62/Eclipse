=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::fits;
our $DEBUG = 1;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

# Uses Excel
use Spreadsheet::ParseExcel;
use File::Temp;

sub key { "fits"; }
sub name { "fits";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.decc.gov.uk/en/content/cms/statistics/energy_stats/source/fits/fits.aspx";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	
	$self->{mech}->get($URL);

	$self->{mech}->follow_link(
	    text => 'Feed in Tariff capacity: monthly update'
	    );

	$self->{mech}->follow_link(
	    text_regex => qr/Download/
	    );

	my $excel = File::Temp->new(
	    suffix => '.xls'
	    );

	print $excel $self->{mech}->content();

	my $parser = Spreadsheet::ParseExcel->new();

	my $wb = $parser->Parse($excel);

	my $ws = $wb->worksheet('Monthly cumulative - CFR');

#
#       CAVEAT: the following scraping code is *heavily* dependent
#       on the layout of the sheet remaining consistent - in particular
#       that the dates will fall on lines 2-3 and the supply figures
#       in lines 6-29 - so, there will never be any new categories,
#       for example. This loos pretty safe, but any changes will need
#       modifications to the code.
#       You have been warned...
#

	our %month = (
	    January   => 1,
	    February  => 2,
	    March     => 3,
	    April     => 4,
	    May       => 5,
	    June      => 6,
	    July      => 7,
	    August    => 8,
	    September => 9,
	    October   => 10,
	    November  => 11,
	    December  => 12
	    );

	# As I said above, we assume tech values (and the rows on which
	# they are found) always remain the same

	my @tech;

	for my $row (6 .. 29) {
	    $tech[$row] = $ws->get_cell($row, 0)->value() . ' / ' . 
		$ws->get_cell($row, 1)-> value();
	}

	my $col = 1;
	my ($year, $mon, $cell);

	while (($cell = $ws->get_cell(2, ++$col)->value()) ne 'month') {

	    if ($cell ne '') {
		$year = $cell;
	    }

	    $mon = $month{$ws->get_cell(3, $col)->value()};

	    my $date = sprintf("%04d-%02d-01", $year, $mon);

	    for my $row (6 .. 29) {

		my $value = $ws->get_cell($row, $col)->unformatted();

		print "$date -  " . $tech[$row] . " : " . $value . "\n" if $DEBUG;
		push @data, [$date, $tech[$row], $value] unless $DEBUG;
	    }
	}

#	my ($row_min, $row_max) = $ws->row_range();

#	my ($col_min, $col_max) = $ws->col_range();

#	for my $row ($row_min .. $row_max) {

#	    for my $col ($col_min .. $col_max) {

#		my $cell = $ws->get_cell($row, $col);

#		next unless $cell;

#		print "$row, $col : " . $cell->value() . "\n" if $DEBUG;

#	    }
#	}
=pod
#1)	INSTRUCTIONS:
1. Go to http://www.decc.gov.uk/en/content/cms/statistics/energy_stats/source/fits/fits.aspx
2. Download xls. "Feed in Tariff capacity: monthly update"
3. In the monthly cumulative tab, collect "installed capacity, by technology" for all months available (gives aggregated data by generation type per month)
4. date should be in YYYY-mm-01 format. ignore the % cols. 
5. So the final array should look like <date,technology,value>


=cut
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


