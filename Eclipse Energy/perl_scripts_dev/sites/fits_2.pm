=pod
Description: Fits data - slight return
Note: The modile DateTime::Format::Excel has not been previously used - will 
need to be added from CPAN.
Also, the updateDB call on line 204 will need some attention
Created by: Andy Holyer
Date: 10/07/12
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::fits_2;
our $DEBUG = 1;
# Scratch flag to stop fetching both Excel files (for me during debugging)
our ($TABLE_1, $TABLE_2) = (1 ,1);

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
use DateTime::Format::Excel;

sub key { "fits_2"; }
sub name { "fits_2";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.decc.gov.uk/en/content/cms/statistics/energy_stats/source/fits/fits.aspx";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;	

	if ($TABLE_1) {
	    $self->{mech}->get($URL);


	    $self->{mech}->follow_link(
		text_regex => qr/Monthly Central Feed-in Tariff/i
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

	    my $ws = $wb->worksheet('Month CFR - Confirmation Date');

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

	    for my $row (75 .. 79) {
		$tech[$row] = $ws->get_cell($row, 2)-> value();
	    }
	    
	    my $col = 2;
	    my ($year, $mon, $m, $cell, $cellv);

	    while (
		(!defined($cell = $ws->get_cell(2, ++$col))) 
		|| (($cellv = $cell->value()) ne '% Monthly Change') 
		){
		
		if (defined($cell) && ($cellv ne '')) {
		    $year = $cellv;
		}

		last unless defined ($m = $ws->get_cell(3, $col));
		$mon = $month{$m->value()};

		my $date = sprintf("%04d-%02d-01", $year, $mon);

		for my $row (75 .. 79) {
		    
		    my $value = $ws->get_cell($row, $col)->unformatted();

		    print "$date -  " . $tech[$row] . " : " . $value . "\n" if $DEBUG;
		    push @data, [$date, $tech[$row], $value] unless $DEBUG;
		}
	    }
	}
# It's lazy, but best to start from scratch again for second table

	if ($TABLE_2) {
	    $self->{mech}->get($URL);


	    $self->{mech}->follow_link(
		text => 'Weekly solar PV installation and capacity'
		);

	    $self->{mech}->follow_link(
		text_regex => qr/Download/
		);

	    my $excel2 = File::Temp->new(
		suffix => '.xls'
		);

	    print $excel2 $self->{mech}->content();

	    my $parser = Spreadsheet::ParseExcel->new();
	    
	    my $wb = $parser->Parse($excel2);

	    my $ws = $wb->worksheet('Capacity_comm');

	    my ($row_min, $row_max) = $ws->row_range();

	    # Real Data starts on row 3
	    for my $row (5 .. $row_max) {

		my $date;
		my $c = $ws->get_cell($row, 0);
		last unless $c;
		my $d = $c->unformatted();
		# There's a misformat on the last line of the Excel.
		# I'm guessing it will be corrected by next week
		# Just in case, we'll do a regexp match anyway
		if ($d =~ m/(\d+)\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec).*(201[0-9])/) {
		    $date = sprintf("%04d-%02d-%02d", $3, $monthToNum{$2}, $1);
		} else {
		    # Drop out when we hit a blank line
		    last unless ($d > 0);
		    $date = DateTime::Format::Excel->
			parse_datetime(
			    $d
			)->ymd();
		}

		my $band0_4 = $ws->get_cell($row, 2)->unformatted();
		my $band4_10 = $ws->get_cell($row, 3)->unformatted();
		my $band10_50 = $ws->get_cell($row, 4)->unformatted();
		
		print "$date: $band0_4, $band4_10, $band10_50\n" if $DEBUG;

		unless ($DEBUG) {
		    push @data, [$date, '0-4', $band0_4];
		    push @data, [$date, '4-10', $band4_10];
		    push @data, [$date, '10-50', $band10_50];
		}
	    }
	}
=pod
1) go to http://www.decc.gov.uk/en/content/cms/statistics/energy_stats/source/fits/fits.aspx
2) click on Monthly Central Feed-in Tariff Register Statistics
3) in the tab Month CFR - Confirmation Date, we want the data in the tab "Installed Capacity, by technology"	
4) we dont need the total. date should be in yyyy-mm-01 format. the final array should look like: <date,type,value>.


1) go to http://www.decc.gov.uk/en/content/cms/statistics/energy_stats/source/fits/fits.aspx
2) click on the link Weekly solar PV installation and capacity
3) in the tab Capacity installed_tariff, we want the data in the first table. dont worry about the total col.date in yyyy-mm-dd.
4) so the final array should look like: <date,tariff_band,value>

=cut
	
	$self->updateDB("eeg.fits_2_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


