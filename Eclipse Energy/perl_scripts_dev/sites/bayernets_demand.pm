=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::bayernets_demand;

our $DEBUG = 0;

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

sub key { "bayernets_demand"; }
sub name { "bayernets_demand";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.bayernets.de/start_netzinformation_en.aspx?int_name=_70436";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	$self->{mech}->get($URL);

	# This site tries to be crafty, and dumps new vistors to the front page
	# We can be even cratier, and fetch the page we want *twice*..
	$self->{mech}->get($URL);

	$self->{mech}->follow_link( text => 'Sales Volumes End-Consumer');

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

	    my $date = $ws->get_cell($row, 1);
	    my $qty = $ws->get_cell($row, 2);
	    next unless $date || $qty; 
	    next if ($date->type() ne 'Numeric');


	    # For kindness, format the date correctly
	    $date->value() =~ m/(\d\d).(\d\d).(\d\d\d\d) (\d\d):(\d\d):(\d\d)/;
	    my $dstring = sprintf("%04d-%02d-%02d:%02d:%02d:%02d", $3, $2, $1, $4, $5, $6);
	    print $dstring . "  : " .  $qty->unformatted() . "\n" if $DEBUG;
	    
	    push @data, [$dstring, $qty->unformatted()] unless $DEBUG;
	}


		
=pod
#1)	INSTRUCTIONS:
1) go to http://www.bayernets.de/start_netzinformation_en.aspx?int_name=_70436	.Might be easy to change the language to english!						
2) click on "Sales volumes end consumer". Note you may/maynot have to click through the whole tree structure again, dependent on cookies.
3) this brings up an excel. load everything into an array in format: <date_time,value>

=cut

	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;

