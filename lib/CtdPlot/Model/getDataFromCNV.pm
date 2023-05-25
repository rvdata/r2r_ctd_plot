package CtdPlot::Model::getDataFromCNV;
#returns an array of data points from .cnv file given an instrument and station

use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get_data($self, $cnv_fullpath_name, $instrument){
    my @instr_data = ();
    my $Debug = 1;
    my $column = $instrument->number;
    #open cnv file
    open (IN, $cnv_fullpath_name)  or die "ERROR: $cnv_fullpath_name not found";
    print STDERR "\nDATAFILE: \$datadir/\$file_in= $cnv_fullpath_name\n" if ($Debug);
    print STDERR "COLUMN:" if ($Debug);
    print STDERR $instrument->number if ($Debug);
    print STDERR "\n" if ($Debug);
    while(<IN>){
        if(!/\*/ && !/\#/){
            my @line = split;
	    push(@instr_data,$line[$instrument->number]);
        }
    }
    close (IN);
return @instr_data;
}
1;
