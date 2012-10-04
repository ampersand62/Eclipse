=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::india_production;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use File::Temp;
use Data::Dumper;
our $DEBUG = 1;

sub key { "india_production"; }
sub name { "india_production";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://petroleum.nic.in/psbody.htm";

sub previous {
    my ($self, $mon, $year) = shift;

    if (--$mon == 0) {
	# We need to wind back to the previous year
	$year--;
	$mon = 12;
	$self->{mech}->select(
	    'year',
	    $year-2000
	    );
	$self->{mech}->submit();
    }

    return ($mon, $year);
}

sub scrape {
    
    my ($mon, $year) = (localtime)[4 .. 5];
    $year += 1900;

    #has the mechanize object. 
    my $self = shift;
    my @data;
    

    # AJH We want a Mech object with autocheck off
    $self->{mech} = WWW::Mechanize->new(
	autocheck => 0
	);
    
    $self->{mech}->get($URL);
    
    $self->{mech}->select(
	'year',
	$year-2000
	);
    ($self->{mech}->forms())[0]->action('http://petroleum.nic.in/petroleum/psbody.jsp');
    $self->{mech}->submit();

#    print Dumper $self->{mech}->content() if $DEBUG;
    # Since this page just has 12 links, this is tricky
    # We have to get the most recent link *which exists*, and
    # the one before

    # Get all this year's links ...
    my @links = $self->{mech}->find_all_links(
	url_regex => qr/Monthly_Production/
	);
	
    # To allow for year wrap, get last year as well...

    $self->{mech}->select(
	'year',
	$year-2001
	);
    ($self->{mech}->forms())[0]->action('http://petroleum.nic.in/petroleum/psbody.jsp');
    $self->{mech}->submit();

    unshift @links, $self->{mech}->find_all_links(
	url_regex => qr/Monthly_Production/
	);

    # Work down from this month (which is $mon+12, since we have two years here
    # until we get the last month which doesn't return a 404, then get the 
    # one before it as well.

    $mon += 12;

    while ($mon >= 0) {

	$self->{mech}->get($links[$mon--]->url());

	last if $self->{mech}->success();
    }
    
    # Get this month's pdf...
    my $pdf = File::Temp->new( suffix => '.pdf');

    print $pdf $self->{mech}->content();

    my $body = File::Temp->new();

    print $body `pdftotext -q -layout $pdf -`;

    $body->seek(0, 0);

    my $date = sprintf(
	"%4d-%02d-01",
	$year-1+int(($mon+1)/12),
	(($mon+1)%12)+1
	);

    while (<$body>) {
	last if m/D. Natural Gas Production/;
    }

    my ($company, $state, $value, $onshore);

    # Scan for lines.....
    while (<$body>) {
	if ( m/\d\. ([^0-9]+?)\s+[0-9.]+/) {
	    $company = $1;
	    $onshore = 1;
	    print "Company = $company\n" if $DEBUG;
	    next;
	}
	if (m/^\s+Offshore\s+[0-9.]+\s+([0-9.]+)/) {
	    $onshore = 0;
	    print "Offshore\n" if $DEBUG;
	    # DGH does not have regions
	    next unless ($company eq 'DGH (Private / JVC)');
	    $value = $1;
	    print "$date: $company, $onshore, Offshore $value\n" if $DEBUG;
	    push @data, [$date, $company, $onshore, 'Offshore', $value];
	    next;
	}

	if (m/^\s+([^0-9.]+?)\s+[0-9.]+\s+([0-9.]+)/) {
	    ($state, $value) = ($1, $2);
	    next if ($state eq 'Onshore');
	    print "$date: $company, $onshore, $state, $value\n" if $DEBUG;
	    push @data, [$date, $company, $onshore, $state, $value];
	}

	last if (m/^TOTAL/); # Bit of a hack, this, but still...
    }
	
    # Now do the same for the month before
    
    $self->{mech}->get($links[$mon]->url());

    $pdf = File::Temp->new( suffix => '.pdf');

    print $pdf $self->{mech}->content();

    $body = File::Temp->new();

    print $body `pdftotext -q -layout $pdf -`;

    $body->seek(0, 0);

    $date = sprintf(
	"%4d-%02d-01",
	$year-1+int(($mon)/12),
	($mon%12)+1
	);

    while (<$body>) {
	last if m/D. Natural Gas Production/;
    }

    # Scan for lines.....
    while (<$body>) {
	if ( m/\d\. ([^0-9]+?)\s+[0-9.]+/) {
	    $company = $1;
	    $onshore = 1;
	    print "Company = $company\n" if $DEBUG;
	    next;
	}
	if (m/^\s+Offshore\s+[0-9.]+\s+([0-9.]+)/) {
	    print "Offshore\n" if $DEBUG;
	    $onshore = 0;
	    # DGH does not have regions
	    next unless ($company eq 'DGH (Private / JVC)');
	    $value = $1;
	    print "$date: $company, $onshore, Offshore, $value\n" if $DEBUG;
	    push @data, [$date, $company, $onshore, 'Offshore', $value];
	    next;
	}

	if (m/^\s+([^0-9.]+?)\s+[0-9.]+\s+([0-9.]+)/) {
	    ($state, $value) = ($1, $2);
	    next if ($state eq 'Onshore');
	    print "$date: $company, $onshore, $state, $value\n" if $DEBUG;
	    push @data, [$date, $company, $onshore, $state, $value];
	}

	last if (m/^TOTAL/); # Bit of a hack, this, but still...
    }



=pod
#1)	INSTRUCTIONS:
1) Go to http://petroleum.nic.in/psbody.htm
2) Select the latest year and months. We should download the last 2 months.
3) In the resulting pdf, we want the data in the last table. Its usually on the last page, but to make sure
please use an assertion/ regex to make sure we are on the the correct one. I think you can do it by checking if the heading start
with "Review of Natural Gas Production".
4) You may need a separate column in the array to distinguish onshore/offshore. The date will be another column in the array, and can be extracted from the heading too and put in format YYYY-MM-01.

=cut
	
	$self->updateDB("eeg.india_production_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


