=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::bafa;
my $DEBUG = 1;
use Data::Dumper;
use Spreadsheet::ParseExcel;
use File::Temp;
use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
our %mon = (
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

use log;
use base qw(Site);

sub key { "bafa"; }
sub name { "bafa";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.bafa.de/bafa/de/energie/erdgas/index.html";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	
	$self->{mech}->get($URL);

	$self->{mech}->follow_link(
	    url => 'ausgewaehlte_statistiken/egasmon_xls.xls'
	    );

	my $excel = File::Temp->new(
	    suffix => '.xls'
	    );

	print $excel $self->{mech}->content();

	my $parser = Spreadsheet::ParseExcel->new();
	my $wb = $parser->Parse($excel);

	my $ws = $wb->worksheet(0);

	my ( $row_min, $row_max ) = $ws->row_range();

        for my $row ( $row_min .. $row_max ) {

	    my $cell = $ws->get_cell( $row, 1 );
	    next unless $cell;

	    next unless $cell->value() =~ m/(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d\d)/;

	    my ($mon, $year) = ($1, $2);
	    my $month = $mon{$mon};
	    $year += 2000;
	    my $date = sprintf("%4d-%02d-01", $year, $month);
	    # Get the other values
	    my %col = (
		Total => 2,
		Domestic_Extraction => 3,
		Total_Import => 4,
		NL => 5,
		NO => 6,
		RU => 7,
		Other_Import => 8,
		Memory_balace => 9,
		Export => 11,
		);
		
	    foreach my $type (keys(%col)) {

		$cell = $ws->get_cell( $row, $col{$type});
		my $value = $cell->unformatted();
		print "$date: $type, $value\n" if $DEBUG;
		push @data, [$date, $type, $value];

            }
        }

	$ws = $wb->worksheet(1);

	# This code makes some pretty big assumptions about the format
	# of the spreadsheet. Firstly that the current year will have
	# three columns of data, all other years two;
	# Secondly I am ignoring the year-on-year columns (they can
	# be calculated later, and would pollute the database)
	# Thirdly, that all historical data will be in the second
	# and later tables, so the historic years in the first table
	# are skipped.
	# If any of these assumptions are wrong, the code will need to be redone.

        ( $row_min, $row_max ) = $ws->row_range();

	my $row;
        for $row ( $row_min .. $row_max ) {

	    # Scan for this year
	    my $cell = $ws->get_cell( $row, 0);
	    next unless $cell;

	    next unless ($cell->value() =~ m/^Jahr/);

	    $cell = $ws->get_cell( $row, 1);
	    my $year = $cell->value();
	    $row += 1; # Skip the headers
	    for my $m (1 .. 12) {
		my $date = sprintf( "%04d-%02d-01", $year, $m);
		$cell = $ws->get_cell( $row+$m, 1);
		my $qty = $cell->unformatted();
		if ($qty > 0) {
		    print "$date Quantity $qty\n" if $DEBUG;
		    push @data, [$date, 'Quantity', $qty];
		}
		$cell = $ws->get_cell( $row+$m, 2);
		my $worth = $cell->unformatted();
		if ($worth > 0) {
		    print "$date Worth $worth\n" if $DEBUG;
		    push @data, [$date, 'Worth', $worth];
		}
		$cell = $ws->get_cell( $row+$m, 3);
		my $price = $cell->unformatted();
		if ($price > 0) {
		    print "$date Price $price\n" if $DEBUG;
		    push @data, [$date, 'Price', $price];
		}
	    };
	    $row +=12;
	    last;
	}
	
	# Now scan for previous years
	while ($row++ <= $row_max) {
	    
	    my $cell = $ws->get_cell( $row, 0);
	    next unless $cell;
	    next unless ($cell->value() =~ m/^Jahr/);

	    my $col = 1;
	    while (my $cell = $ws->get_cell( $row, $col)) {
		last unless ((my $year = $cell->value()) > 0);

		for my $m (1 .. 12) {
		    my $date = sprintf( "%04d-%02d-01", $year, $m);
		    $cell = $ws->get_cell( $row+$m+1, $col);
		    my $qty = $cell->unformatted();
		    print "$date Quantity $qty\n" if $DEBUG;
		    push @data, [$date, 'Quantity', $qty];
		    $cell = $ws->get_cell( $row+$m+1, $col+1);
		    my $price = $cell->unformatted();
		    print "$date Price $price\n" if $DEBUG;
		    push @data, [$date, 'Price', $price];
		}
		$col += 2;
	    }
	    $row += 13;
        }

=pod
#1)	INSTRUCTIONS:
1) Go to http://www.bafa.de/bafa/de/energie/erdgas/index.html
2) Click on the 2nd link called "Aufkommen und Export von Erdgas sowie die Entwicklung der Grenzübergangspreise ab 1991 XLS (xls 83 KByte)" which is on the right hand side of the page
3) In the excel sheet, grab all the columns in the first tab called "Bilanz...". We dont need the last 3 rows, just the ones with monthly numbers.
4) get rid of commas and turn the months into a date format YYYY-MM-01.
5) So the final array should look like: (date,type,value)

6) Then go to the second tab called "Imp Preise". We want the data from the whole table. Note 2012 data will be added soon so we have to write the script in order for it to find it when it arrives and not hard code the cells we look for.
7) Get rid of commas. We also dont need the last row "gesamp".
8) so the final array should look like: (date,type,value).

=cut

	
	$self->updateDB("eeg.bafa_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


