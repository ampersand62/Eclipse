=pod
Description: --- Put Description of Code Here ---
Created by: Andy Holyer
Date: 20/04/12
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::gaspool_hub_liquidity;
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

sub key { "gaspool_hub_liquidity"; }
sub name { "gaspool_hub_liquidity";}
sub usesWWW { 1; }
#
my %monthNum = (
    January => 1,
    February => 2,
    March => 3,
    April => 4,
    May => 5,
    June => 6,
    July => 7,
    August => 8,
    September => 9,
    October => 10,
    November => 11,
    December => 12
    );


#URL of website to scrape
my $TRADED = "http://www.gaspool.de/hub_handelsvolumina.html?&L=1";
my $DELIVERED = "http://www.gaspool.de/hub_churn_rate.html?&L=1";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	# Traded figures
	$self->{mech}->get($TRADED);

	$self->{mech}->follow_link(
	    text_regex => qr/Excel File/
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

	    # Date col 1, Hgas 2, Lgas 3
 
	    my $cell = $ws->get_cell( $row, 1);
	    
	    next unless $cell && 
		$cell->value() =~ m/(January|February|March|April|May|June|July|August|September|October|November|December) (\d\d\d\d)/;

	    my ($mon, $year) = ($1, $2);
	    
	    my $date = sprintf("%04d-%02d-01", $year, $monthNum{$mon});
	    
	    my $hgas = $ws->get_cell($row, 2)->unformatted();
	    my $lgas = $ws->get_cell($row, 3)->unformatted();

	    print "$date: $hgas, $lgas\n" if $DEBUG;
	    push @data, [$date, $hgas, $lgas];
	}

	# Delivered figures

	$self->{mech}->get($DELIVERED);

	$self->{mech}->follow_link(
	    text_regex => qr/PDF/
	    );

	my $pdf = File::Temp->new(
	    suffix => '.pdf'
	    );

	print $pdf $self->{mech}->content();

	my $body = File::Temp->new();

	print $body `pdftotext -q -layout $pdf -`;

	$body->seek(0, 0);

	while (<$body>) {
	    if ($_ =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d\d)\s+([0-9,]+)\s+[0-9,]+\s+[0-9.]+\s+([0-9,]*)/g) {
		my $date = sprintf("%04d-%02d-01", $2+2000, $monthToNum{$1});
		my $hgas = $3;
		my $tgas = $4;

		$hgas =~ s/,//g;
		$tgas =~ s/,//g;

		print "$date: $hgas, $tgas\n" if $DEBUG;
		push @data, [ $date, $hgas, $tgas];
	    }
	}
=pod
#1)	INSTRUCTIONS:
1. This has 2 parts; traded and delivered. For traded, go to: http://www.gaspool.de/hub_handelsvolumina.html?&L=1
2. Download the Excel file
3. Collect both the h-gas and l-gas columns
4. Turn the month into a database date format YYYY-MM-01. The final array should look like: <date,type,h-gas value,l-gas value>
5. For delivered, Go to: http://www.gaspool.de/hub_churn_rate.html?&L=1 
6. Download pdf at the bottom of the page,  collect "Physical Quantities KWh" in both the h gas and l gas columns.
7. date format should be YYYY-MM-01. Remove commas. The final array should look like: <date,type,h-gas value,l-gas value>



=cut

	
	$self->updateDB("eeg.gaspool_hub_liquidity_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


