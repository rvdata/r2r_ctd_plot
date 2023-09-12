package CtdPlot::Model::InstrListFromCNV2;

use strict;
use warnings;
use experimental qw(signatures);

sub new { bless {}, shift }

sub get ( $self, $file_in) {
        my @instruments = ();
        my $numb;
        my $extra_info;
        my $units;
        my $instrument_name;
        my $Debug=0;
        my @extra_fields;
	#my $file_in = $_[0];
        open (IN, $file_in)  or die "nope no $file_in";
        print STDERR "DATAFILE: \$datadir/\$file_in= $file_in\n" if ($Debug);
        while(<IN>){
                if(/\# name/){
                        ( my $first_half, my $second_half ) = split(':');
                        ($numb, $instrument_name) = ($first_half =~ /\# name (\d{1,2}) = (\D.*)/);
                        print STDERR "NUMBER: $numb\n" if ($Debug);
                        $instrument_name =~ tr/\//_/;   #  change "/" to "_"
                        $instrument_name =~ tr/-/_/;    #  change "-" to "_"
                        $instrument_name =~ s/a-.00/a_T/; #change -. to _T
                        print STDERR "INSTR NAME: $instrument_name\n" if ($Debug);
			#($extra_info, $units) = ($second_half =~ /(.*)\[(.*)\]/);
                        if(/.*\[.*\]/){
                            ($extra_info, $units) = ($second_half =~ /(.*)\[(.*)\]/);
		        }else{
                            $extra_info = $second_half;
			    #remove carriage return
			    $extra_info =~ s/\R//g;
			    $units="";
			}
                        print STDERR "EXTRA INFO: $extra_info\n" if ($Debug);
                        print STDERR "UNITS: $units \n" if ($Debug);
                        @extra_fields = split(',',$extra_info);
                        my $instrument = Instrument->new();
                        $instrument->name($instrument_name);
                        $instrument->number($numb);
                        $instrument->units($units);
                        $instrument->quantity_measured($extra_info);
			push(@instruments,$instrument);
                }
        }
        close (IN);
        return @instruments;
}

1;

