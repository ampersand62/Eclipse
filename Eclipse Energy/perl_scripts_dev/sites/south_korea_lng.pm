=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::south_korea_lng;
our $DEBUG = 1;
use Data::Dumper;
use File::Temp;
use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub prev_month{
    my ($year, $month) = @_;

    if ($month == 1) {
	return(--$year, 12);
    } else {
	return($year, --$month);
    }
}

sub key { "south_korea_lng"; }
sub name { "south_korea_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://english.customs.go.kr/kcsweb/user.tdf?a=user.itemimportexport.ItemImportExportApp&c=1001&mc=ENGLISH_INFORMATION_TRADE_040";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;	
	$self->{mech}->get($URL);

#	print Dumper($self->{mech}->content()) if $DEBUG;

	my ($mon, $year) =(gmtime)[4, 5];
	# Correct these values
	$mon++;
	$year += 1900;


	# Too complex to well-form this loop
	while(1) {

	    my $date = sprintf("%04d-%02d-01", $year, $mon);

	    $self->{mech}->form_name('viewsearch');
	    
	    $self->{mech}->select( 'SelectGubun', 10);

	    $self->{mech}->set_fields(
		hs2 => 27,
		hs4 => 11,
		hs6 => 11,
		hs10 => '0000',
		isType => 1,
		);

	    {
		local $^W = 0;
		$self->{mech}->field(
		    c => 1001
		    )
	    }
	    
	    $self->{mech}->set_fields(
		selectYear => $year,
		selectMonth => $mon
		);

	    $self->{mech}->submit();

	    my $hit = 0;

	    my $result = File::Temp->new();

	    binmode $result, ":utf8"; # Stops unicode warning

	    print $result $self->{mech}->content();

	    $result->seek(0, 0);
	    while (<$result>) {
		next unless /<td height=\"26\" class=\"td_center\">(.*)<\/td>/;
		my $country = $1;
#		print "Country $country\n" if $DEBUG;
		# Throw away next line 
		$_ = <$result>;
		$_ = <$result>;
		$_ =~ m|<td class=\"td_right\" style=\"padding-right:5px;\">([\d,]+)</td>|;
		my $usd = $1;
		$usd =~ s/,//g;
#		print "USD $usd\n" if $DEBUG;
		# And again...
		$_ = <$result>;
		$_ = <$result>;
		$_ =~ m|<td class=\"td_right\" style=\"padding-right:5px;\">([\d,]+)</td>|;
		my $wt = $1;
		$wt =~ s/,//g;
#		print "Weight $wt\n" if $DEBUG;
		# Once more with feeling...
		$_ = <$result>;
		$_ = <$result>;
		$_ =~ m|<td class=\"td_right\" style=\"padding-right:5px;\">([\d,]+)</td>|;
		my $qty = $1;
		$qty =~ s/,//g;
#		print "Qty $qty\n" if $DEBUG;

		if ($usd || $wt || $qty) {
		    $hit = 1;
		    print "$date $country $usd $wt $qty\n" if $DEBUG;
		}

		push @data, [$date, $country, $usd, $wt, $qty];
	    }

	    if ($hit) {
	
		$self->updateDB("eeg.south_korea_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
		#exits the method
		return 1;
	    }
	    # otherwise go back a month
	    print "No result for $date\n" if $DEBUG;
	    
	    undef $result; # Make sure we get a new temp file if we need to go round again
	    ($year, $mon) = prev_month($year, $mon);
	    @data = ();
	}
=pod
1) Go to http://english.customs.go.kr/kcsweb/user.tdf?a=user.itemimportexport.ItemImportExportApp&c=1001&mc=ENGLISH_INFORMATION_TRADE_040								
2) Year-Month takes any input in yyyy and mm form.Try the current year and month. If no result, then go back and try to get the last 3 months.
3) H/S Unit should be 10 units. HS code being 2711110000 which should be separated as:	27	11	11	0000.
4) Ensure import is selected.
5) We want everything in the left hand side of the table (the month that we searched the data for, and not the same month for last year).
6) Get rid of commas. The date should be in format: YYYY-MM-01. So the final array shoul look like: (date,country,usd,weight,quantity)



=cut

	
}

1;


