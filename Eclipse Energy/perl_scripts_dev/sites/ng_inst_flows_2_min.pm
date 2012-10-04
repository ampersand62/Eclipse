=pod
Description: Scrape of Vantionl Grid
Created by: Andy Holyer
Date: 17 August 2012
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::ng_inst_flows_2_min;

our $DEBUG = 1;
use File::Temp;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "ng_inst_flows_2_min"; }
sub name { "ng_inst_flows_2_min";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://energywatch.natgrid.co.uk/EDP-PublicUI/Public/InstantaneousFlowsIntoNTS.aspx";

sub sdate {
    my $stamp = shift;
    
    $stamp =~ m!(\d\d)/(\d\d)/(\d\d\d\d) (\d\d):(\d\d)!;

    return "$3-$2-$1:$4:$5";
}

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	$self->{mech}->get($URL);

	# Get round the javascript to get the CSV

	$self->{mech}->field('__EVENTTARGET', 'a1');
	$self->{mech}->field('__EVENTARGUMENT', '');

	$self->{mech}->submit();

	my $temp = File::Temp->new();
	print $temp $self->{mech}->content();

	$temp->seek(0, 0);

	while (<$temp>) {
	    # Header lines have lower-case letters in them
	    next if (/[a-z]/);
	    chomp;
	    my ($name, $published, $value, $timestamp, $expired, $amended, $astamp, $subst, $late) = split /,/;

	    $published = sdate($published);
	    $timestamp = sdate($timestamp);
	    if ($astamp ne '') {
		$astamp = sdate($astamp)
	    }

	    print "$published: $name, $value, $timestamp, $expired, $amended, $astamp, $subst, $late\n" if $DEBUG;
	    push @data, [ $published, $name, $value, $timestamp, $expired, $amended, $astamp, $subst, $late] unless $DEBUG;
	}
=pod
#1)	INSTRUCTIONS:
1) Go to http://energywatch.natgrid.co.uk/EDP-PublicUI/Public/InstantaneousFlowsIntoNTS.aspx
2) Download the CSV at the bottom of the page. Please use this rather than the html download as it gives more info.
3) We'd like all the columns. You'll notice that half way down there is another heading; please ignore that.
4) Dates should be in yyyy-mm-dd. 

=cut
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


