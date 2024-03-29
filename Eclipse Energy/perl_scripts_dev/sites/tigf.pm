=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::tigf;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use Data::Dumper;
use File::Temp;
our $DEBUG = 1;

sub key { "tigf"; }
sub name { "tigf";}
sub usesWWW { 1; }


#URL of website to scrape
my $URL = "http://tetra.tigf.fr/SBT/public/FluxPhysiques.do?action=liste";

sub scrape {

	my @data;	
	#has the mechanize object. 
	my $self = shift;

	my ($day, $mon, $year) = (gmtime)[3 .. 5];

	$mon++; $year += 1900;

	$self->{mech}->get($URL);

	my ($lastmonth, $today);

	if ($mon == 1) {
	    $lastmonth = sprintf("%02d/%02d/%04d", $day, 12, $year-1);
	} else {
	    $lastmonth = sprintf("%02d/%02d/%04d", $day, $mon-1, $year);
	};

	$today = sprintf("%02d/%02d/%04d", $day, $mon, $year);

	$self->{mech}->form_name("FiltreFluxPhysiquesForm");

	$self->{mech}->set_fields(
	    validiteDebut => $lastmonth,
	    validiteFin => $today
	    );

	$self->{mech}->submit();

	my $result = File::Temp->new();

	print $result $self->{mech}->content();

	$result->seek( 0, 0);

	while (<$result>) {

	    next unless /<td class=\"date\">(\d+)\/(\d+)\/(\d+)<\/td>/;
	    my ($d, $m, $y) = ($1, $2, $3);

	    my $date = sprintf("%04d-%02d-%02d", $y, $m, $d);
	    # We want the first entry in each of the next four sets 
	    # of three columns (if that makes sense)
	    for my $point ('PTT-GRTGAZSUD', 'PTT-LARRAU', 'PTT-BIRIATOU', 'PITS') {
		# Two blank lines
		$_ = <$result>;
		$_ = <$result>;

		$_ = <$result>;

		$_ =~ m|<td.*>(.*)</td>|;
		my $flow = $1;
		if ($flow eq '-') {
		    $flow = 0;
		} else {
		    # Remove non-breaking spaces
		    $flow =~ s/\x{a0}//g;
		}
		print "$date $point, $flow\n" if $DEBUG;
		push @data, [ $date, $point, $flow];

		# Throw away the next two columns
		$_ = <$result>;
		$_ = <$result>;
		# and the blank line
		$_ = <$result>;
	    }

	}

#	print Dumper $self->{mech}->content() if $DEBUG;
=pod
#1)	INSTRUCTIONS:
1) GO to http://tetra.tigf.fr/SBT/public/FluxPhysiques.do?action=liste
2) Set the from date to a month ago and set the to date to today's date and hit display.
3) We'd like the date in format yyyy-mm-dd, all 4 selected network points data in kWh @ 25C.
4) So the final data should look like: (date,point name, flow value in kwh)


=cut

	
	$self->updateDB("eeg.tigf_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


