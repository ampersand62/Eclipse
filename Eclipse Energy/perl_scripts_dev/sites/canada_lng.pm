=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::canada_lng;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use Data::Dumper;
use File::Temp;
use Spreadsheet::ParseExcel;
use base qw(Site);

sub key { "canada_lng"; }
sub name { "canada_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.neb-one.gc.ca/clf-nsi/rnrgynfmtn/sttstc/mprtlqufdntrlgs/mprtlqufdntrlgs-eng.html";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

	my @data;

	$self->{mech}->get($URL);

	$self->{mech}->follow_link(
	    text_regex => qr/Imports of Liquified Natural Gas/,
	    n => 1
	    );

	my $excel = File::Temp->new(
	    suffix => '.xls'
	    );

	print $excel $self->{mech}->content();

#	print Dumper $excel;

	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->Parse($excel);

	for my $worksheet ( $workbook->worksheets() ) {

	    my ( $row_min, $row_max ) = $worksheet->row_range();
	    my ( $col_min, $col_max ) = $worksheet->col_range();

	    for my $row ( $row_min .. $row_max ) {

		my $cell = $worksheet->get_cell( $row, 0 );
		next unless $cell;
		
		if ((my $date = $cell->value) =~ /(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d{2})/) {
		    my $month = $1;
		    my $year = $2;

		    my $mon = $monthToNum{$month};

		    my $date = sprintf( "20%02d-%02d-01", $year, $mon);

		    $cell = $worksheet->get_cell( $row, 4);
		    my $volume = $cell->value;

		    $cell = $worksheet->get_cell( $row, 6);

		    my $source = $cell->value;

		    push @data, [$date, $volume, $source];

		    print ">> $date $volume $source\n";
		}
	    }
	}

=pod
#1)	INSTRUCTIONS:
1) Go to http://www.neb-one.gc.ca/clf-nsi/rnrgynfmtn/sttstc/mprtlqufdntrlgs/mprtlqufdntrlgs-eng.html
2) Click on the link "Imports of Liquified Natural Gas - ......." xls. Download the file.
3) We want the date in col A, the volumes in col E called "LNG Volume (Gas Equivalent) " and the country of origin in col G from both tables.
4) Again, the date should be in format YYYY-MM-01. 
5) Note that new months will be appended to the tables with new ship arrivals.
6) So the final array should look like: (date,quanitity,source).

=cut
	
	$self->updateDB("eeg.canada_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


