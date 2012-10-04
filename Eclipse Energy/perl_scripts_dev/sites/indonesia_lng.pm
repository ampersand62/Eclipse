=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::indonesia_lng;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use Data::Dumper;
our $DEBUG = 1;

sub key { "indonesia_lng"; }
sub name { "indonesia_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://dds.bps.go.id/eng/exim-frame.php";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	
	# Change this when 2012 data is in
	my $year = 2011;

	$self->{mech}->get($URL);
	$self->{mech}->form_number(2);


	$self->{mech}->field('thn', $year);

	$self->{mech}->field('jenis', 4);
	$self->{mech}->field('sumber', 1);
	$self->{mech}->field('hscd', 2);
	$self->{mech}->field('nmhs', '27111100');
	$self->{mech}->submit();


#       The output is very poorly formatted, so I extract the required table 
#       from the output and then parse it

	$self->{mech}->content() =~ m!(<table BORDER.*</table>)!;

	my $table = $1;

	use HTML::TableContentParser;
	my $p = HTML::TableContentParser->new();
	my $fields = $p->parse($table);

	for my $t (@$fields) {
	    foreach my $row (@{$t->{rows}}) {
		my @cells = @{$row->{cells}};

		my $d = $cells[0]->{data};

		if ($d =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/) {
		    my $mon = $monthToNum{$1};
		    my $date = sprintf("%04d-%02d-01", $year, $mon);

		    my $value = $cells[1]->{data};
		    my $weight = $cells[2]->{data};

		    $value =~ s/ //g;
		    $weight =~ s/ //g;

		    print "$date: Value = $value, Weight = $weight\n" if $DEBUG;
		    push @data, [$date, $value, $weight];
		}
	    }
	}
=pod
#1)	INSTRUCTIONS:
1) Go to http://dds.bps.go.id/eng/exim-frame.php								
2) On the left hand side, Select Export and the latest year (we dont get 2012 yet, so have to retry for previous year). Select the description radio button and then enter the code 27111100 in the Description text field
3) Press 'Proses/Run'
4) We want all the data in the resulting table. The month should be translated into a date field in format YYYY-MM-01.
5) Otherwise, grab the price and weight columns and load into one multi-dim array of format <date,price,volume>

=cut
	
	$self->updateDB("eeg.indonesia_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


