package CtdPlot::Model::getDataFromCNV;
#returns an array of data points from .cnv file given an instrument object and cnv full path
use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get_data($self, $cnv_fullpath_name, $x_instrument, $y_instrument){
    my @x_instr_data = ();
    my @y_instr_data = ();
    #open cnv file
    open (IN, $cnv_fullpath_name)  or die "ERROR: $cnv_fullpath_name not found";
    while(<IN>){
        if(!/\*/ && !/\#/){
            my @line = split;
	    my $xval = $line[$x_instrument->number];
	    my $yval = $line[$y_instrument->number];

	    #prDM,depSM must be negated
	    $xval = (($x_instrument->name eq "prDM")  or ($x_instrument->name eq "depSM")) ?  -$xval : $xval;
	    $yval = (($y_instrument->name eq "prDM")  or ($y_instrument->name eq "depSM")) ?  -$yval : $yval;

	    push(@x_instr_data,$xval);
	    push(@y_instr_data,$yval);
        }
    }
    close (IN);
return (\@x_instr_data,\@y_instr_data);
}
1;
