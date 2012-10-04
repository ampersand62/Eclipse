=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---

# --- Please dont edit anything in this section. Feel free to add Perl modules to use --- #
=cut
package Site::bbl_flows;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use HTML::TableContentParser;
#use Data::Dumper;
use Date::Calc;

sub key { "bbl_flows"; }
sub name { "bbl_flows";}
sub usesWWW { 1; }
#

# URL of website to scrape
my $URL = "http://info.bblcompany.com";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my $mech = $self->{mech};
#	$mech->get($URL);
# Dig into the frameset
#	$mech->follow_link( url=> 'home.aspx');
#	$mech->follow_link( text => 'Flow Information' );

# This is a terrible hack, but reverse-engineering the site to get 
# past the JavaScript...
	$mech->get("$URL/HistoricalFlow.aspx");
# I realize this could be easily broken were they to reorganize the site, 
# but 'twill do for now.

	my ($y, $m, $d) = Today();
	my ($yy, $mm, $dd) = Add_Delta_Days($y, $m, $d, -14);

	my $today = sprintf("%02d-%02d-%d",$d, $m, $y);
	my $twoweeksago = sprintf("%02d-%02d-%d",$dd, $mm, $yy);

# I admit to resorting to google to find this hack (which gets round the
# .Net WebForm_DoPostbackWithOptions issue)
	$mech->
	    form_number(1)
	    ->push_input (
		'hidden', 
		{ id => 'ctl00$cphFilter$UCDataFilter$lbShowTable',
		  name => 'ctl00$cphFilter$UCDataFilter$lbShowTable',
		  value => 1
		}
	    );

	$mech->submit_form(
	    fields => {
		'ctl00$cphFilter$UCDataFilter$ddlHistoricalInterval' => 24,
		'ctl00$cphFilter$UCDataFilter$tbxStartGasDay' => $twoweeksago,
		'ctl00$cphFilter$UCDataFilter$ddlStartGasTime' => "06:00",
		'ctl00$cphFilter$UCDataFilter$tbxEndGasDay' => $today,
		'ctl00$cphFilter$UCDataFilter$ddlEndGasTime' => "06:00",
		'ctl00$cphFilter$UCDataFilter$ddlTimebase' => "Bst",

	    }
	    );

# The data we want is in one of the tables in the retrned document
	my $tp = HTML::TableContentParser->new();
	my $tables = $tp->parse($mech->content());

	# final array
	my @data;
	
	foreach my $table (@$tables) {
# We only want the last of these tables which has class 'RepeaterTable'	    
	    next unless (exists($table->{class}) && ($table->{class} eq 'RepeaterTable'));
#	    print Dumper( \$table);
	    # Iterate through the remaining rows of the table
	    foreach my $row (@{$table->{rows}}) {
		next if ($row->{cells}[0]->{data} =~ /<strong>/); # Discard the header row
		# Each row has the following cells: 
		# Start Date, End Date, Physical Flow, Forward flow, Reverse Flow 
		# The three flow figures are formatted by european conventions 
		# (i.e.dots for thousands, and presumably a comma for decimal point
		my ( $start_d, $end_d, $phys, $forward, $reverse) =
		    map { $_->{data} } @{$row->{cells}};
		$phys = uneuro_number($phys);
		$forward = uneuro_number($forward);
		$reverse = uneuro_number($reverse);

		push @data, [ $start_d, $phys, $forward, $reverse];
		
	    }
#	    print Dumper \@data
	}

=pod
#1)	INSTRUCTIONS:
	1)PUT ALL CODE WHICH SCRAPES A WEBSITE IN HERE.
	2)PUT LOG MSGS IN THE CODE USING THE info(...) method from log.pm
	3)Go to the above link, and then click on 'Flow Information' and 'Historical flow' on the left. 
	Choose interval 'Gas Day', choose from 6am a week ago to 6am this morning, choose BST for timebase, 
	and click 'Download data'. From the resulting spreadsheet, we want the data in start date, physical flow, forward flow and reverse flow columns.
	4) We'd like the data in a multi-dim array which we can then load into a database.
	
=cut

	# this will print the array to a file in the backup dir
	$self->updateDB("eeg.bbl_flows",["a","b","c"],["d"],\@data,name());
		
	# exits the method
	return 1;
	
}

sub uneuro_number {
    my $num = shift;
    $num =~ s/\.//g;
    $num =~ s/,/\./;
    return $num;
}

1;


