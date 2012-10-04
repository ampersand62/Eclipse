#!/usr/bin/perl -w
use warnings;
use strict;
our @INC = (@INC, "..");

my %site;

use misc qw(parseDate);
use log;

use sites::bbl_flows;Site::bbl_flows->register(\%site);

sub usage {
	my $usage = <<EOM;
  $0 <site> [args...]

  Date may usually be specified very flexibly and/or relatively:
    2008-01-30              = 30th of January, 2008
    yesterday               = yesterday's date
    12 hours ago            = date as it was 12 hours ago
    1 week ago              = 7 days ago
    etc.

  And 'site' is one of the following:
EOM
	$usage .= sprintf "    %-30s %s\n", (sprintf "%s %s", $_, $site{$_}->[0]), $site{$_}->[1] foreach (sort keys %site);

	print $usage;
}

sub getSite {
	my $s = shift;
	return undef unless exists $site{$s};
	return $site{$s}->[2];
}

if(@ARGV < 1 || not exists $site{$ARGV[0]}) {
	usage;
	exit;
}

#eegdbi::connect;

#my ($dt,$st) = (shift, shift);

package eegdbi;
my $st = shift;


log_info("SCRIPT $st has been INVOKED");


#if(grep { not callSite($site{$st}->[2],$_,@ARGV); } parseDate($dt)) {
#	complain(2, "Errors occured");
#}


my @imacros_scripts = ("enagas","eon_storage_2","gas_roads","ontras");

callSite($site{$st}->[2],@ARGV);

sub callSite {
	my $fn = shift;
	my $ret = 0;
	eval { $ret = $fn->(@_); };
	if($@ ne "") {
		complain(2, $@);
		if (grep {$_ eq $st} @imacros_scripts) {
			info("Failed: $@\n",$st);
		}
		print STDERR "Failed: $@\n";
	}
	else{	
		log_info("SCRIPT $st has FINISHED OK\n");
				
	}
	
	return $ret;
}
