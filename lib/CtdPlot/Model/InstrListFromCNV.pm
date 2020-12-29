package CtdPlot::Model::InstrListFromCNV;

use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get ( $self, $file_in) {
        my @insts;
        my $numb;
        my $extra_info;
        my $units;
        my $instrument_name;
        my $Debug=0;
        my @extra_fields;
	#my $file_in = $_[0];
        open (IN, $file_in)  or die "nope no $file_in";
        print STDERR "\$datadir/\$file_in= $file_in\n" if ($Debug);
        while(<IN>){
                if(/\# name/){
                        ( my $first_half, my $second_half ) = split(':');
                        ($numb, $instrument_name) = ($first_half =~ /\# name (\d{1,2}) = (\D.*)/);
                        $instrument_name =~ tr/\//_/;   #  change "/" to "_"
                        $instrument_name =~ tr/-/_/;    #  change "-" to "_"
                        $instrument_name =~ s/a-.00/a_T/; #change -. to _T
                        ($extra_info, $units) = ($second_half =~ /(.*)\[(.*)\]/);
                        @extra_fields = split(',',$extra_info);
                        $insts[$numb] = Instrument->new();
                        $insts[$numb]->name($instrument_name);
                        $insts[$numb]->units($units);
                        $insts[$numb]->quantity_measured($extra_info);
                }
        }
        close (IN);
        return @insts;
}

1;
