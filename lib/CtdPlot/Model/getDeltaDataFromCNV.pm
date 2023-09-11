package CtdPlot::Model::getDeltaDataFromCNV;
#returns an array of data points from .cnv file given an instrument object and cnv full path
use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get_delta_data($self, $cnv_fullpath_name, $x_instrument1, $x_instrument2, $y_instrument){
    my @x_instr_data = ();
    my @y_instr_data = ();
    if($x_instrument1->{_exists} && $x_instrument2->{_exists} && $y_instrument->{_exists}){
         #open cnv file
         open (IN, $cnv_fullpath_name)  or die "ERROR: $cnv_fullpath_name not found";
	 while(<IN>){
		 if(!/\*/ && !/\#/){
			 my @line = split;
			 my $x1val = $line[$x_instrument1->{_column}];
			 my $x2val = $line[$x_instrument2->{_column}];
			 my $yval = $line[$y_instrument->{_column}];
			 
	    		 #prDM,depSM must be negated
	                 $yval = (($y_instrument->{_name} eq "prDM") or ($y_instrument->{_name} eq "depSM")) ?  -$yval : $yval;
			
			 push(@x_instr_data,$x1val-$x2val);
			 push(@y_instr_data,$yval);
		 }
	 }
	 close (IN);
    }
    return (\@x_instr_data,\@y_instr_data);
}
1;
