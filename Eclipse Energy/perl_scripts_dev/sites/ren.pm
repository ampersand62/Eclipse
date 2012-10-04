=pod
Description: Scrape for ren.pt
Note $DEBUG, and in this file only $XLS1 and $XLS2 to scrape only one or other
(or both, or neither) of the two links.
Note, I have noticed the links to these XLS files on the home page appear to 
change over time (I think they post the four most-recently-updated Excel sheets 
on the home page). I have noted that on occasion one or both of them vanish - they 
are still available via drill-down but that makes the code significantly harder. 
Created by: Andy Holyer
Date: 04 April 2012
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::ren;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use Spreadsheet::ParseExcel;
use File::Temp;
use Data::Dumper;

sub key { "ren"; }
sub name { "ren";}
sub usesWWW { 1; }
#
our $DEBUG = 1;
our $XLS1 = 1;
our $XLS2 = 1;
#URL of website to scrape
my $URL = "https://www.ign.ren.pt/en/";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	my $parser = Spreadsheet::ParseExcel->new();



	if ($XLS1) {
	    $self->{mech}->get($URL);

	    $self->{mech}->follow_link( 
		text_regex => qr/na RNTIAT/
		);
	
	    my  $exist = File::Temp->new(
		suffix => '.xls'
		);  
	    print $exist $self->{mech}->content();

	    my $workbook = $parser->Parse($exist);

#	    print Dumper $workbook->worksheets() if $DEBUG;

	    # Because of accented characters in the sheet titles, refer to them by 
	    # number, not name
	    foreach my $sheet (1 .. 2) {
		my $ws = $workbook->worksheet($sheet);
		
		my $type = ('', 'TGNL', 'AS')[$sheet];

		my ($min, $max) = $ws->row_range();

		for (my $row = $min; $row <= $max; $row++) {
		    my $dcell = $ws->get_cell($row, 0);
		    next unless $dcell;
		    next unless $dcell->type() eq 'Date';
		
		    my $date = $dcell->value();
		    my $stock = ($ws->get_cell($row, 1))->unformatted();
		    my $capacity = ($ws->get_cell($row, 2))->unformatted();
		    next unless $stock;
		    print "$date: $type, $stock, $capacity\n" if $DEBUG;
		    push @data, [$date, $type, $stock, $capacity];
		}
	    }
	}

	# Capacidades sheet
	if ($XLS2) {
	    $self->{mech}->get($URL);
	    $self->{mech}->follow_link(
		text_regex => qr/RNTGN/
		);
	    my $capac = File::Temp->new(
		suffix => '.xls'
		);
	    print $capac $self->{mech}->content();

	    my $wb2 = $parser->Parse($capac);

	    my $sheet = 0;
	    foreach my $ws ($wb2->worksheets()) {
		my $type = (
		    'Badajoz',
		    'LNG sendout',
		    'Stock change',
		    'Tuy',
		    'High Pressure Clients',
		    'Other offtakes'
		    )[$sheet];

		my ($min, $max) = $ws->row_range();
		my ($entry, $exit);
		for (my $row = $min; $row <= $max; $row++) {
		    my $dcell = $ws->get_cell($row, 0);
		    next unless $dcell;
		    next unless $dcell->type() eq 'Date';
		
		    my $date = $dcell->value();
		    my $cell = $ws->get_cell($row, 5)->unformatted();
		    next if ($cell eq '');

		    if ($sheet <=3) {
			$entry = $cell;
			$exit = ($ws->get_cell($row, 11))->unformatted();
		    } else {
			$entry = 0;
			$exit = $cell;
		    }

		    print "$date: $type, $entry, $exit\n" if $DEBUG;
		    push @data, [$date, $type, $entry, $exit];
		}
		
		$sheet++;
	    }
	}

=pod
#1)	INSTRUCTIONS:

1) Go to https://www.ign.ren.pt/en/
2) We want the data in the links called "Existências na RNTIAT" and "Capacidades e PCS nos Pontos Relevantes da RNTGN"
3) In the Existencias spreadsheet download:
- There are three tabs. We want the data on the Existencias_TGNL and Existencias_AS tabs
- Existencias_TGNL gives the stock level and available capacity of LNG storage. We want both. Same goes for Exsitencias_AS. Amount of gas is the stock level and available capacity, but for underground storage.
4) The date should be in YYYY-MM-DD format. So the final array should look like: <date, type,stock_level,available_capacity>

5) In the Capacidades spreadsheet download:
- We are interested in the data in all tabs. The information we need:
	-  physical entry flows and physical exit flows (columns F and L) in tabs Camp_Major, terminal, AS and Valenca
	-  physical flows  in Clientes_AP and Outra_saidas (column F) should be put in a column called "exit flows"
- Campo Mejor flows should be called Badajoz, Terminal flows should be called LNG sendout, AS should be called stock change, valenca should be called Tuy, Clientes_AP should be called High Pressure Clients, Outra_saidas should be called other offtakes.
6) Date should be in normal format. So the final array should look like: <date,point,entry_flow, exit_flow>

=cut

	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


