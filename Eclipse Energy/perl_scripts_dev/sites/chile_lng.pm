
=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::chile_lng;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use Data::Dumper;
use File::Temp;
use log;
use base qw(Site);

sub key { "chile_lng"; }
sub name { "chile_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $BASE = "http://200.72.160.89/estacomex/asp/";
my $REL =  "ConsItemPais.asp?sistema=2&Glosa=27111100&Tipo=1";
my $URL = $BASE.$REL;
# Reverse-engineered the Javascript to correct the URL fetched
our %esmon = (
    Ene => '01',
    Feb => '02',
    Mar => '03',
    Apr => '04',
    May => '05',
    Jun => '06',
    Jul => '07',
    Aug => '08',
    Sep => '09',
    Oct => '10',
    Nov => '11',
    Dic => '12' );

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	$self->{mech}->get($URL);

	# Since the form uses Javascript to submit, we need to mess 
	# around with the values (and hence with the URL)

	($self->{mech}->forms())[0]->action($BASE . 'ResumenItemPais.asp?Glosa=27111100&Buscar=B&sistema=2');

        $self->{mech}->select( 'sel_clave', '27111100');

        $self->{mech}->submit();
        
	my $result = File::Temp->new();

	print $result $self->{mech}->content();
	
	open RESULT, "<$result";

	my ($month, $year, $date, $country, $qty, $price);
	# Scan to start of the table we want - a "</thead>" tag is our clue...
	while (<RESULT>) {
	    if (/(Ene|Feb|Mar|Apr|May|Jun|Jul|Ago|Sep|Oct|Nov|Dic)\/(20\d\d)/) {
		($month, $year) = ($1, $2);
		$date = $year . "-" . $esmon{$month} . '-01';
	    }
	    last if /<\/thead>/;
	};

	# Now we need the country line - which has a NOWRAP flag

	while (<RESULT>) {
	    next unless /NOWRAP >([A-Z ]+) <\/td>/;
	    $country = $1;
	    # Skip two lines, then a number, skip a line, number
	    my $line = <RESULT>;
	    $line = <RESULT>;
	    $line = <RESULT>;
	    $line =~ m/right>([0-9,]+)/;
	    $qty = $1;
	    $qty =~ s/,//g;
	    $line = <RESULT>;
	    $line = <RESULT>;
	    $line =~ m/right>([0-9,]+)/;
	    $price = $1;
	    $price =~ s/,//g;

	    print "!!$date -  $country, $qty, $price\n"; # Delete for production
	    push @data, [$date, $country, $qty, $price]
	}



=pod
1)	INSTRUCTIONS:
1) Go to http://200.72.160.89/estacomex/asp/ConsItemPais.asp?sistema=2. (Might help if you use chrome for translations :)
2) Set the Period to the latest month/year with data
3) Put "27111100" in the search box. This is the code.
4) Click Search. 
5) Then choose the item type as "27111100-gas natual....".
6) Click search again.
7) We want the data in the 3rd,6th and 8th Columns called "Cantidad"/"Number Ene-Nov/2011" and Valor(US$)/Value (U.S. $) Ene-Nov/2011
8) We want to get rid of the commas in both columns. The date can be extracted from the table header in the 6th Column, so it should look like YYYY-MM-01.
9) The final array should look like this: (date,country,quantity,price).

=cut

	
	$self->updateDB("eeg.chile_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


