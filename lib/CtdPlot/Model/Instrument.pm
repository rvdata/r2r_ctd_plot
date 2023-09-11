package CtdPlot::Model::Instrument;

use strict;
use warnings;
use experimental qw(signatures);

sub new {
    my $class = shift;
    my $self = {
            _cnv_file 	=> shift,
            _name 	=> shift,
            _column 	=> 0,
            _property 	=> "",
            _units 	=> "",
            _exists 	=> 0,
    };

    bless $self, $class;
    ($self->{_column},$self->{_property},$self->{_units}) = $self->_init();
    return $self;
}

sub _init {
        my ($self) = @_;
	my ($numb,$extra_info,$units);
	open (IN, "$self->{_cnv_file}")  or die "ERROR: cannot open $self->{_cnv_file}";
        while(<IN>){
                if(/\# name.*$self->{_name}/){
                        my ($first_half, $second_half ) = split(':');
                        ($numb, my $instrument_name) = ($first_half =~ /\# name (\d{1,2}) = (\D.*)/);
                        if(/.*\[.*\]/){
                            ($extra_info, $units) = ($second_half =~ /(.*)\[(.*)\]/);
                        }else{
                            $extra_info = $second_half;
                            #remove carriage return
                            $extra_info =~ s/\R//g;
                            $units="";
                        }
			$self->{_exists} = 1;
			last;
                }
        }
        close (IN);
        return ($numb,$extra_info,$units);
}
1;
