#!/usr/bin/env perl
#to test: "./ctd_plot.pl get /"
#or ./ctd_plot.pl get -v '/?filename=ar44027_1db.cnv'
use Mojolicious::Lite -signatures;
use Class::Struct;
use lib qw(lib);
use CtdPlot::Model::InstrListFromCNV;
use CtdPlot::Model::CNV2CSV;
#use CtdPlot::Model::CNV2CSVString;

my $datadir = "/home/data/armstrong/ctd/";
my $index=0;
my $Debug=1;
#if -d option given, override datadir and remove from ARGV before passing to mojo
foreach my $arg (@ARGV) {
    if($ARGV[$index] eq "-d"){
       $datadir = $ARGV[$index+1];
       splice(@ARGV, $index, 1);
       splice(@ARGV, $index, 1);
       last;
    }
    $index++;
}

struct Instrument => {
        name => '$',
        instr_number => '$',
        quantity_measured => '$',
        units => '$',
};

my @instruments;
my $instruments = [];
my @cnv_info;
my @stations_selected;

get '/' => sub ($c) {
  #get entire list of cnv files from data dir for user to select from
  opendir DATADIR, "$datadir" or die "no data directory\n";
  my @stations =  sort grep (/cdn$|cnv$/, readdir (DATADIR));
  close DATADIR;

  #get list of selected stations from browser multiselect form
  for my $key (@{$c->req()->params()->names}) {
      my $station_array_ref = $c->req()->every_param($key);
      #reset stations selected so it doesn't double count
      @stations_selected=();
      foreach(@$station_array_ref){
          print STDERR ("pushing station: ".$_."\n") if ($Debug);
	  push(@stations_selected,$_);
      }
  };

  #set first file as template to obtain instruments, they all should be the same
  my $first_station = $stations_selected[0];
  print STDERR ("first station ".$stations_selected[0]."\n");
  
  #create .dat and csv file for each cnv file
  foreach my $station (@stations_selected) {
      my @cnv_file;
      print STDERR ("station selected: $station\n") if ($Debug);
      my $dat_file = "public/$station".".dat";
      printf STDERR ("dat file: %s\n", $dat_file) if ($Debug);
      my $input_filename = "${datadir}$station";
      print STDERR ("full path name: ".$input_filename."\n") if ($Debug);

      #create list of instrument objects from cnv file
      helper instr_list => sub { state $instr_list = CtdPlot::Model::InstrListFromCNV->new };
      @instruments = $c->instr_list->get($input_filename);

      #create csv file with instrument header for plotly
      helper cnv2csv => sub { state $cnv2csv = CtdPlot::Model::CNV2CSV->new };
      @cnv_info = $c->cnv2csv->convert($input_filename,$dat_file,\@instruments);
  }
  print STDERR ("stations: ");
  foreach my $station (@stations_selected) {
	  print STDERR ($station."\n");
  }

  #Send data to client 
  $c->stash(fileSelection	=> $first_station);
  $c->stash(stationslist	=> \@stations_selected);
  $c->stash(stafilelist		=> \@stations);
  $c->stash(instrumentlist	=> \@instruments);
  $c->stash(cnv_info		=> \@cnv_info);
  $c->render( template		=> 'index');
};

app->log->debug('Starting application');
app->start;
