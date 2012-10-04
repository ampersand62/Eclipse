=pod
Description: Scrape of PDF file on snamretegas.it
Created by: Andy Holyer
Date: 03/05/2012
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::psv_hub_liquidity;
our $DEBUG = 1;
use File::Temp;
use Data::Dumper;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "psv_hub_liquidity"; }
sub name { "psv_hub_liquidity";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.snamretegas.it/en/services/Thermal_Year_2011_2012/info-to-users/dati-logistica-gas-index.html";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
		
	$self->{mech}->get($URL);

	$self->{mech}->follow_link(
	    url_regex => qr/progressivi/
	    );

	my $pdf = File::Temp->new(
	    suffix => '.pdf'
	    );

	print $pdf $self->{mech}->content();

	my $body = File::Temp->new();

	print $body `pdftotext -q -raw $pdf - `;

	# This is a bit tricky, since the table is quite minimal, and 
	# the year is only indicated below the table. So we're looking for 
	# several things. I rely on the year display starting in October,
	# so Oct-** will terminate the scan

	$body->seek(0, 0);

	# This is just wierd because the month starts in October. Sorry...
	my %monum = (
	    October => 10,
	    November => 11,
	    December => 12,
	    January => 13,
	    February => 14,
	    March => 15,
	    April => 16,
	    May => 17,
	    June => 18,
	    July => 19,
	    August => 20,
	    September => 21
	    );
	my @figs;
	my $year;
	while(<$body>) {
	    if ($_ =~ m/(October|November|December|January|February|March|April|May|June|July|August|September)\s+([0-9.,]*)/) {
		my ($month, $traded) = ($1, $2);
		print "$month: $traded\n" if $DEBUG;
		$traded =~ s/\.//;
		$traded =~ s/,/./;
		push @figs, [$monum{$month}, $traded];
		next;
	    }
	    if ($_ =~ m/Oct-(\d\d)/) {
		$year = 2000 + $1;
	    }
	    if ($_ =~ m/TOTAL/) {
		last;
	    }
	}

	for my $fig (@figs) {
	    my ($month, $traded) = @$fig;
	    my $y = $year;
	    if ($month > 12) {
		$y++;
		$month -= 12;
	    }
	    my $date = sprintf( "%04d-%02d-01", $y, $month);
	    print "$date: $traded\n" if $DEBUG;
	    push @data, [$date, $traded];
	}
	
=pod
#1)	INSTRUCTIONS:
1) - Go to http://www.snamretegas.it/en/services/Thermal_Year_2011_2012/info-to-users/dati-logistica-gas-index.html
2) Under the section "Final Gas Transactions at VTP", select the most recent pdf download
3) In the first page of the pdf pick up the gas traded data from the table (overlays graph) (input as "Traded" in database)
4) The . should be removed and the comma should be a decimal. the year could be taken from the axis or/link name.
5) date should be in format YYYY-MM-01. the final array should look like: <date,value>

=cut

	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


