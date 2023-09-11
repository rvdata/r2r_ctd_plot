package CtdPlot::Model::Graph;
#Graph object to pass to plotly
#describes graph Title and Axes labels

use strict;
use warnings;
use experimental qw(signatures);

sub new {
    my $class = shift;
    my $self = {
            _name 	=> shift,
            _x_label 	=> "",
            _y_label 	=> "",
    };

    bless $self, $class;
    return $self;
}

sub addXLabel {
   my ( $self, $x_label ) = @_;
   $self->{_x_label} = $x_label if defined($x_label);
}

sub addYLabel {
   my ( $self, $y_label ) = @_;
   $self->{_y_label} = $y_label if defined($y_label);
}
1;
