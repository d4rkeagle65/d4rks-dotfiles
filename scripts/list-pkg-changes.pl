#!/usr/bin/perl -w
use strict;

my @files = ("aur_package_install_list.txt","package_initial_install_list.txt","package_install_list.txt");

my %explicitPkgs;
foreach ( (split('\n',`pacman -Qet`)) ) { $explicitPkgs{ (split(' ',$_))[0] }++; }

foreach (@files) {
	open my $fh, '<', ('/srv/git/d4rks-dotfiles/configs/' . $_) or die $!;
	chomp(my @file = <$fh>);
	close $fh;

	foreach (@file) {
		if (exists $explicitPkgs{$_}) {
			$explicitPkgs{ $_ }--;
		}
	}
}

my @out;
foreach (keys %explicitPkgs) {
	if ($explicitPkgs{$_} >= 1 ) {
		push @out,$_;
	}
}

foreach (@out) {
	my $cmdOut = (split('\s',((split("\n",`trizen -Ss $_ | grep $_ | grep -e 'installed'`))[0])))[0];
	print $cmdOut . "\n";
}

exit;