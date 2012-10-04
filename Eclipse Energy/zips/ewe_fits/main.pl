#!/usr/bin/perl
use warnings;
use strict;
our @INC = (@INC, "..");

my %site;

use misc qw(parseDate);
use log;

use sites::bbl_flows;Site::bbl_flows->register(\%site);
use sites::japan_lng;Site::japan_lng->register(\%site);
use sites::synergrid;Site::synergrid->register(\%site);
use sites::chile_lng;Site::chile_lng->register(\%site);
use sites::canada_lng;Site::canada_lng->register(\%site);
use sites::bafa;Site::bafa->register(\%site);
use sites::korea_lng;Site::korea_lng->register(\%site);
use sites::south_korea_lng;Site::south_korea_lng->register(\%site);
use sites::canada_monthly_lng;Site::canada_monthly_lng->register(\%site);
use sites::us_monthly_lng;Site::us_monthly_lng->register(\%site);
use sites::tigf;Site::tigf->register(\%site);
use sites::thailand_lng;Site::thailand_lng->register(\%site);
use sites::italian_storage;Site::italian_storage->register(\%site);
use sites::peru_lng;Site::peru_lng->register(\%site);
use sites::indonesia_lng;Site::indonesia_lng->register(\%site);
use sites::india_production;Site::india_production->register(\%site);
use sites::ssb;Site::ssb->register(\%site);
use sites::ren;Site::ren->register(\%site);
use sites::cegh_hub_liquidity;Site::cegh_hub_liquidity->register(\%site);
use sites::gaspool_hub_liquidity;Site::gaspool_hub_liquidity->register(\%site);
use sites::ttf_hub_liquidity;Site::ttf_hub_liquidity->register(\%site);
use sites::zb_hub_liquidity;Site::zb_hub_liquidity->register(\%site);
use sites::psv_hub_liquidity;Site::psv_hub_liquidity->register(\%site);
use sites::fits;Site::fits->register(\%site);
use sites::bayernets_flows;Site::bayernets_flows->register(\%site);
use sites::bayernets_demand;Site::bayernets_demand->register(\%site);
use sites::fits_2;Site::fits_2->register(\%site);
use sites::wmo;Site::wmo->register(\%site);
use sites::gasunie_zuidwending;Site::gasunie_zuidwending->register(\%site);
use sites::grtgaz_daily;Site::grtgaz_daily->register(\%site);
use sites::ng_inst_flows_2_min;Site::ng_inst_flows_2_min->register(\%site);
use sites::ewe;Site::ewe->register(\%site);






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
