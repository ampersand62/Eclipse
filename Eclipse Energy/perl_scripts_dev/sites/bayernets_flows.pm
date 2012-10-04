=pod
Description: Scrape of Bayernets.de
Created by: Andy Holyer
Date: 17/06/2012
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::bayernets_flows;
our $DEBUG = 0;

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

sub key { "bayernets_flows"; }
sub name { "bayernets_flows";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.bayernets.de/start_netzinformation_en.aspx?int_name=_70417";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	$self->{mech}->get($URL);
	# Twice, to fool the cookie store
	$self->{mech}->get($URL);

	$self->{mech}->follow_link(text => 'Load Flow Volumes Current Gas Year');

	my $excel = File::Temp->new(
	    suffix => '.xls'
	    );

	print $excel $self->{mech}->content();
	
	my $parser = Spreadsheet::ParseExcel->new();

	my $wb = $parser->Parse($excel);

	my $ws = $wb->worksheet(0);

	my ($row_min, $row_max) = $ws->row_range();

	my ($col_min, $col_max) = $ws->col_range();

	for my $row ($row_min .. $row_max) {

	    # In this Excel:
	    # Col 1 => Date
	    # Col 2 => Hour
	    my %cols = (
		3 => 'Haiming UP2',
		4 => 'Inzenham UGS Entry',
		5 =>  'Inzenham UGS exit',
	        6 =>  'Kiefersfelden',
	        7 =>  'Pfronten',
                8 =>  'Ueberackern',
	        9 =>  'Wolfersberg UGS entry',
                10 => 'Wolfersberg UGS exit'
		);

	    my $date = $ws->get_cell($row, 1);

	    next unless $date; 
	    next unless ($date->type() eq 'Numeric') && ($date->value() =~ m/(\d\d)\.(\d\d)\.(\d\d\d\d)/);

	    my ($day, $mon, $year) = ($1, $2, $3);
	    my $hour = $ws->get_cell($row, 2);

	    my @cells;

	    for my $i (3 .. 10) {
		$cells[$i] = $ws->get_cell($row, $i)->unformatted();
	    }

	    my $d = sprintf("%04d-%02d-%02d:%02d:00:00", $year, $mon, $day, $hour->value());
	    for my $i (3 .. 10){
		
		print "$d > " . $cols{$i} . " " . $cells[$i] . "\n" if $DEBUG;
		push @data, [$d, $cols{$i}, $cells[$i]] unless $DEBUG;
	    }
	}
	
=pod
#1)	INSTRUCTIONS:
1) go to http://www.bayernets.de/start_netzinformation_en.aspx?int_name=_70417	. Might be easy to change the language to english!						
2) click on network information, then expand the tree by clicking the + sign on nomination and load flows, then "load flow data currently"
3) this brings up an excel. load everything into an array in format: <date_time,point,value>

=cut

	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


