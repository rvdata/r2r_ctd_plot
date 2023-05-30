package CtdPlot::Model::getDeltaDataFromCNV;
#returns an array of data points from .cnv file given an instrument object and cnv full path
use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get_delta_data($self, $cnv_fullpath_name, $x_instrument1, $x_instrument2, $y_instrument){
    my @x_instr_data = ();
    my @y_instr_data = ();
    #open cnv file
    open (IN, $cnv_fullpath_name)  or die "ERROR: $cnv_fullpath_name not found";
    while(<IN>){
        if(!/\*/ && !/\#/){
            my @line = split;
	    my $x1val = $line[$x_instrument1->number];
	    my $x2val = $line[$x_instrument2->number];
	    my $yval = $line[$y_instrument->number];

	    #prDM must be negated
	    $yval = ($y_instrument->name eq "prDM") ?  -$yval : $yval;

	    push(@x_instr_data,$x1val-$x2val);
	    push(@y_instr_data,$yval);
        }
    }
    close (IN);
return (\@x_instr_data,\@y_instr_data);
}
1;
