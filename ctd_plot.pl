#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Class::Struct;
use CGI qw(escapeHTML);

struct Instrument => {
        name => '$',
        instr_number => '$',
        quantity_measured => '$',
        units => '$',
};

my @instruments;
my $instruments = [];
my @cnv_info;

get '/' => sub ($c) {
  #get cnv file name from user, initially equal to ''
  my $filename = $c->param('filename');

  #populate client with cnv files
  my $datadir = "/home/data/armstrong/ctd/";
  opendir DATADIR, "$datadir" or die "no data directory\n";
  my @stafiles =  sort grep (/cdn$|cnv$/, readdir (DATADIR));
  close DATADIR;

  my $input_filename = "${datadir}/${filename}";
  @instruments = get_instr_info_from_cnv($input_filename);
  
  my $out_file = "public/ctd.dat";
  @cnv_info = cnv_to_csv($input_filename,$out_file,\@instruments);

  $c->stash(fileSelection	=> $filename);
  $c->stash(stafilelist		=> \@stafiles);
  $c->stash(instrumentlist	=> \@instruments);
  $c->stash(cnv_info		=> \@cnv_info);
  $c->render( template		=> 'index');
};


sub get_instr_info_from_cnv{
        my @insts;
        my $numb;
        my $extra_info;
        my $units;
        my $instrument_name;
        my $Debug=0;
        my @extra_fields;
        my $file_in = $_[0];
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

sub cnv_to_csv{
	my $numb;
	my $Debug=0;
	my $sys_date;
	my $lon_sec;
	my $lat_sec;
	my $lon_min;
	my $lat_min;
	my @line;
	my $index;
	my %stuff;
	my $cap_file;
	my $t;
	my $s;
	my $extra;
	my %ctd_var;
	my $var;
        my $in_file  =  $_[0];
        my $out_file =  $_[1];
        my $aref  =  $_[2];
        my $num_instruments = scalar @$aref;
        my @info;

        open (IN, $in_file)  or die "nope no $in_file";
        open (OUT,">$out_file") or die "cannot create $out_file";
        print STDERR "\$datadir/\$file_in= $in_file\n" if ($Debug);
        #print data file header comma seperated
        # pointer to first element of array
        my $k = $aref->[0];
        for($index= 0; $index < $num_instruments-1; $index++){
                $k = $aref->[$index];
                printf OUT ("%s,", $k->name);
        }
        $k = $aref->[$num_instruments-1];
	#printf OUT ("%s\n", $k->name);
        $cap_file = uc($_[0]);
        while (<IN>)
        {
                if(  ($numb, $var) = /\# name (\d{1,2}) = (\D.*): / )
 {
                $var =~ tr/\//_/;                                       #  change "/" to "_"
                $var =~ s/a-.00/a_T/;
                $ctd_var{$var} =  $numb;
                #print STDERR "\$ctd_var{$var} = $ctd_var{$var}\n" if ($Debug);
                if ( ($ctd_var{t190C} != 0)  && ($ctd_var{sal11} != 0 ))
                        {
                                $extra = 1;
                                $s = 4;
                                $t = 3;
                                print STDERR "you have redundant temp and cond\n" if ($Debug);
                        }
                        else
                        {
                        $extra = 0 ;
                        $s = 3;
                        $t = 2;
                        }
                }
                if (/^\# sensor/ && /Extrnl/ && !/PAR/)
                {
                        @line = split;
                        $stuff{$line[7]} = $line[6];
                }
                elsif (/NMEA/ && /Lat/)
                {
                        @line = split;
                        $lat_min = $line[4];
                        $lat_sec = $line[5];
                }
                elsif (/NMEA/ && /Lon/)
   {
                        @line = split;
                        $lon_min = $line[4];
                        $lon_sec = $line[5];
                }
                elsif (/System UpLoad/)
                {
                        $sys_date = substr($_,23);
                }
                elsif (!/\*/ && !/\#/)
                {
                        @line = split;
                        my $k = $aref->[0];
                        for($index= 0; $index < $num_instruments-1; $index++){
                                $k = $aref->[$index];
                                #prDM must be negated
                                if( ($k->name) eq "prDM"){
                                        printf OUT "%s, ", -$line[$index];
                                } else {
                                        printf OUT "%s, ", $line[$index];
                                }
                        }
                        printf OUT "%s\n", $line[$num_instruments-1];
                }
        }
close (OUT);
close (IN);
push(@info, $lat_min, $lat_sec, $lon_min, $lon_sec,  $sys_date);
#print "<h4 style=\"text-align:center;\">$cap_file:  $lat_min &#176 $lat_sec N  $lon_min &#176 $lon_sec W  $sys_date gmt</h4>\n";
#return "<h4 style=\"text-align:center;\">$cap_file:  $lat_min &#176 $lat_sec N  $lon_min &#176 $lon_sec W  $sys_date gmt</h4>\n";
return @info;
}



app->start;
