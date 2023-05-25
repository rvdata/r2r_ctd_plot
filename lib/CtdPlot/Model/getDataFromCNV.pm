package CtdPlot::Model::getDataFromCNV;
#returns an array of data points from .cnv file given an instrument object and cnv full path
use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get_data($self, $cnv_fullpath_name, $instrument){
    my @instr_data = ();
    #open cnv file
    open (IN, $cnv_fullpath_name)  or die "ERROR: $cnv_fullpath_name not found";
    while(<IN>){
        if(!/\*/ && !/\#/){
            my @line = split;
	    my $val = $line[$instrument->number];
	    #prDM must be negated
	    $val = ($instrument->name eq "prDM") ?  -$val : $val;
	    push(@instr_data,$val);
        }
    }
    close (IN);
return @instr_data;
}
1;
