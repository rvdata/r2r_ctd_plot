package CtdPlot::Model::InstrListFromCNV;
##################################################
# return list of instrument names from cnv file
##################################################

use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get ( $self, $file_in) {
        my @instruments = ();
        my $Debug=0;
        open (IN, $file_in)  or die "ERROR: unable to open $file_in";
        print STDERR "DATAFILE: \$datadir/\$file_in= $file_in\n" if ($Debug);
        while(<IN>){
                if(/\# name/){
                        my ($first_half, $second_half ) = split(':');
                        my ($numb, $instrument_name) = ($first_half =~ /\# name (\d{1,2}) = (\D.*)/);
                        print STDERR "NUMBER: $numb\n" if ($Debug);
                        $instrument_name =~ tr/\//_/;   #  change "/" to "_"
                        $instrument_name =~ tr/-/_/;    #  change "-" to "_"
                        $instrument_name =~ s/a-.00/a_T/; #change -. to _T
                        print STDERR "INSTR NAME: $instrument_name\n" if ($Debug);
			push(@instruments,$instrument_name);
                }
        }
        close (IN);
        return @instruments;
}

1;

