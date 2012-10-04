=pod
Description: Scrape CEGH spreadsheet. Only the Monthly figures. Could 
             potentially extend to add daily figures if needed
Created by: Andy Holyer
Date: 19/04/12
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::cegh_hub_liquidity;
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

sub key { "cegh_hub_liquidity"; }
sub name { "cegh_hub_liquidity";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.ceghotc.com/index.php?id=231";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	
	$self->{mech}->get($URL);

	$self->{mech}->follow_link(
	    text_regex => qr/CEGH Volumes/
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
	    
	    my $cell = $ws->get_cell( $row, 1);
	    next unless $cell;

	    next unless $cell->value() =~ m/\d\d\d\d-\d\d/;

	    my $net = $ws->get_cell($row, 2)->unformatted();
	    my $throughput = $ws->get_cell($row, 3)->unformatted();

	    next unless $net && $throughput;

	    my $date = $cell->value() . '-01';

	    print "$date, $net, $throughput\n" if $DEBUG;

	    push @data, [$date, $net, $throughput];
	}
=pod
#1)	INSTRUCTIONS:
1. Go to: http://www.ceghotc.com/index.php?id=231
2. Download "CEGH volumes" spreadsheet 
3. Collect Net Traded Volume data TWh and Physical Throughput TWh
4. The date should be in format YYYY-MM-01. The final array should look like: <date,net,throughput>


=cut

	
	$self->updateDB("eeg.cegh_hub_liquidity_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


