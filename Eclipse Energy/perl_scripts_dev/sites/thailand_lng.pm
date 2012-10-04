=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::thailand_lng;

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
our $MONTHSBACK = 4;

our %MON = (
    JAN => 1,
    FEB => 2,
    MAR => 3,
    APR => 4,
    MAY => 5,
    JUN => 6,
    JUL => 7,
    AUG => 8,
    SEP => 9,
    OCT => 10,
    NOV => 11,
    DEC => 12
);


sub key { "thailand_lng"; }
sub name { "thailand_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape

my $URL = "http://search.customs.go.th:8090/Customs-Eng/Statistic/StatisticIndex2550.jsp";
# my $URL = "http://search.customs.go.th:8090/Customs-Eng/Statistic/Statistic.jsp?menuNme=Statistic";

sub scrape {

	my @data;	
	#has the mechanize object. 
	my $self = shift;

	my ($mon, $year) = (gmtime)[4, 5];
	$year += 1900;

	# Slight cheat this, based on the fact that we want last 
	# month and before
	if ($mon == 0) {
	    $mon = 12;
	    $year--;
	}

	for my $count ( 1 .. $MONTHSBACK) {

	    $self->{mech}->get($URL);

	    $self->{mech}->set_fields(
		productCodeCheck => 1,
		productCode => 27111100000,
		statType => 'import',
		month => $mon,
		year => $year
		);

	    $self->{mech}->submit();

	    my $result = File::Temp->new();
	
	    print $result $self->{mech}->content();

	    $result->seek( 0, 0);

	    # Scan to get the date

	    while (<$result>) {

		next unless /class="HeadTable1" width="20%">([A-Z]{3})&nbsp;/;
		
		my $mon = $MON{$1};
		
		$_ = <$result>;
		
		$_ =~ m!(\d*)</td>!;
	
		my $year = $1;

		my $date = sprintf( "%04d-%02d-01", $year, $mon);

		# Scan ahead for the country
		while (<$result>) {
		    next unless /<td colspan="3"> ([A-Z ]*)<\/td>/;
		    
		    my $country = $1;
		    ($_ = <$result>) =~ m!<td align="right">([0-9,]*)</td>!;
		    my $qty = $1;
		    $qty =~ s/,//g;
		    $_ = <$result>;
		    $_ = <$result> =~ /([0-9,]+)/;
		    my $cif = $1;
		    $cif =~ s/,//g;
		
		    print "$date $country $qty $cif\n" if $DEBUG;
		    push @data, [$date, $country, $qty, $cif];
		}

	    }
	 
	    # Step back a month...
	    $mon--;
	    if ($mon == 0) {
		$mon = 12;
		$year--;
	    }
	}


=pod
#1)	INSTRUCTIONS:
1) Go to http://search.customs.go.th:8090/Customs-Eng/Statistic/Statistic.jsp?menuNme=Statistic
2) Click on "Import - Export Statistics from January 2007 to Current"
3) Check "HS Code". Use code: 27111100000. Check "Import"
4) We want to download the data from the last 3 months, so maybe have a loop for each month.
5) In the resulting table,we want the data in the left hand side of the table (for the month we searched for). We want the month
and year from the header to make the date in yyyy-mm-01 format,the country , quantity and CIF Value(Baht) columns. No
need for the total row at the bottom.
6) So the final array should look like: (date,country,quantity,value)


=cut

	
	$self->updateDB("eeg.thailand_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


