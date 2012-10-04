=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::italian_storage;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

our $DEBUG = 1;
use Data::Dumper;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::Utility 'ExcelLocaltime';
use File::Temp;

sub key { "italian_storage"; }
sub name { "italian_storage";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.snamretegas.it/en/services/Thermal_Year_2011_2012/Gas_transportation/Storage_operational_data/index.html";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	my $parser = Spreadsheet::ParseExcel->new();

	$self->{mech}->get($URL);

	my %link;
        $link{'stogit'} = $self->{mech}->find_link(
	    url_regex => qr/stogit-EN.xls/
	    );

	$link{'edison'} = $self->{mech}->find_link(
	    url_regex => qr/edison-EN.xls/
	    );

	for my $src ('stogit', 'edison') {

	    $self->{mech}->get($link{$src}->url());

	    my $excel = File::Temp->new(
		suffix => '.xls'
		);

	    print $excel $self->{mech}->content();

	    my $wb = $parser->Parse($excel);

	    # The workbook is split up into one sheet per month
	    # To slightly complicate matters, the workbook may include 
	    # some "trash" sheets at the end. So, we need to work from the last
	    # sheet backwards until we find one which is valid...
	    my $sheetno = $wb->worksheet_count(); 

            # work back through the sheets, usual array-starts-with-0
	    my $sheet;
	    do {
		
		$sheet = $wb->worksheet(--$sheetno);

	    } until ($sheet->get_name() =~ m/201\d/);


	    sub scan_sheet {
		my ($sheet, $src) = @_;
		my @data;

		print "Scanning " . $sheet->get_name() . " ($src)\n" if $DEBUG;

		my ( $row_min, $row_max ) = $sheet->row_range();
		my ( $col_min, $col_max ) = $sheet->col_range();

		for my $row ( $row_min .. $row_max ) {

		    my $cell = $sheet->get_cell( $row, 0);
		    next unless ($cell && ($cell->type() eq 'Date')) ;

		    # We need the date extracted, and the values in cols 4 and 5

		    my ($day, $mon, $year) = 
			(ExcelLocaltime($cell->unformatted()))[3 .. 5];
		     
		    my $date = sprintf("%02d-%02d-%04d", $day, $mon+1, $year+1900);
		    my $daily = $sheet->get_cell( $row, 4)->unformatted();
		    my $stock = $sheet->get_cell( $row, 5)->unformatted();

		    print "$src $date: $daily, $stock\n" if $DEBUG;

		    # Executive Decision: Only submit database entry if daily 
		    # flow is non-zero

		    if ($daily) {
			push @data, [$date, $src, $daily, $stock]; 
		    }
		}

		return @data;
	    };

	    push @data, scan_sheet($sheet, $src);
	    push @data, scan_sheet($sheet=$wb->worksheet(--$sheetno), $src);
	}

#	print Dumper @data if $DEBUG;
=pod
#1)	INSTRUCTIONS:
1) Go to http://www.snamretegas.it/en/services/Thermal_Year_2011_2012/Gas_transportation/Storage_operational_data/index.html
2) We want to download both the stogit and edison stocagio excel sheets.
3) From them we want the data for yesterday's month, as well as last month.
4) We want the day, the daily flow (mwh) and stock level (mwh) data from both the spreadsheets. Date should be in format YYYY-mm-dd. Get rid of commas in the number fields.
5) Load the data into 1 array. (date,operator,flow,stock_level).


=cut

	
	$self->updateDB("eeg.italian_storage_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


