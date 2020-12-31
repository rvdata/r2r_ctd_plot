package CtdPlot::Model::Instrument;


use strict;
use warnings;
use experimental qw(signatures);


sub new { bless {}, shift }

struct Instrument => {
        name => '$',
        instr_number => '$',
        quantity_measured => '$',
        units => '$',
};


}


1;
