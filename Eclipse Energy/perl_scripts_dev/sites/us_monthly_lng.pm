=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::us_monthly_lng;
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
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::Utility qw(ExcelLocaltime);
use File::Temp;
sub key { "us_monthly_lng"; }
sub name { "us_monthly_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.fossil.energy.gov/programs/gasregulation/publications/";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	
	$self->{mech}->get($URL);

	$self->{mech}->follow_link( url_regex => qr/xls$/);

	my $excel = File::Temp->new(
	    suffix => '.xls'
	    );

	print $excel $self->{mech}->content();

	my $parser = Spreadsheet::ParseExcel->new();

	my $wb = $parser->Parse($excel);

	my $ws = $wb->worksheet('LNG Imports');

	my ( $row_min, $row_max ) = $ws->row_range();
	my ( $col_min, $col_max ) = $ws->col_range();

	# Counter for which table we're in
	my $table_no = 0;
	my $in_table = 0;
	my $longshort;

	for my $row ( $row_min .. $row_max ) {

	    my $cell = $ws->get_cell( $row, 1);
	    next unless $cell;
	    
	    # Scan for start of first table
	    # Data is badly formed - sometimes this is 
	    # actually a string with the date. Bah!
	    unless (
		($cell->type() eq 'Numeric') ||
		($cell->value() =~ m!(\d{1,2})/(\d{1,2})/(\d{4})!)
		) {
		$in_table=0;
		next;
	    }

	    my ($sec, $min, $hr, $day, $mon, $year) =
		($cell->type() eq 'Numeric') ?
		ExcelLocaltime($cell->unformatted()) :
		(0, 0, 0, $2, $1-1, $3-1900);

	    my $date = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $day);
	    
	    # Check if we've just stumbeld on a table
	    if ($in_table == 0) {
		$longshort = ('short', 'long', 'none')[$table_no++];
		$in_table = 1;
	    }

	    # Slurp the other cols into an array
	    my @cols;

	    for my $col (2 ..9) {
		push @cols, $ws->get_cell( $row, $col)->unformatted();
	    }

	    my $spot="no";
	    my $spotcell = $ws->get_cell($row, 12);
	    if ($spotcell && ($spotcell->value() eq 'J')) {
		$spot = "yes";
	    }

	    print "$date: $longshort, spot=$spot, " . (join ", ", @cols) . "\n" if $DEBUG;
	    push @data, [$date, $longshort, $spot, @cols ];
	}

#	print Dumper @data if $DEBUG;

=pod
1) Go to http://www.fossil.energy.gov/programs/gasregulation/publications/
2) At the bottom of the page, there is a link called "2011 - MONTHLY REPORT - NOVEMBER [127 KB PDF] [Excel Version]". It will change with month and year. Click the "Excel version".
3) In the excel file, click on LNG imports tab. We want all 3 tables. The first 2 tables can go in one array but can be distinguished by a flag called "short_long_term". All the rows in the first table should have "short term" in the "short_long_term" field and the second table should have "long term".
4) Also notice the smiley faces at the end which seem to be encoded as "J". We should have another column called "spot". If there is a smiley face in that particular row, then the column spot should have a value "yes" for that row. If there is no smily face, then have "no".
5) For the last table (puerto rico imports), there doesn't need to be a value for "short_long_term".
6) Again, dates should be in format YYYY-MM-01.


=cut

	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


