#!/usr/bin/env perl
#to test: "./ctd_plot.pl get /"
#or ./ctd_plot.pl get -v '/?filename=ar44027_1db.cnv'
use Mojolicious::Lite -signatures;
use Class::Struct;
use lib qw(lib);
use CtdPlot::Model::InstrListFromCNV;
use CtdPlot::Model::CNV2CSV;
use CtdPlot::Model::getDataFromCNV;
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
        number => '$',
        quantity_measured => '$',
        units => '$',
};

my @instruments;
my $instruments = [];
my @cnv_info;
my @all_cnv_info;
my @cnv_files_selected = ();

get '/' => sub ($c) {
  #get entire list of cnv files from data dir for user to select from
  opendir DATADIR, "$datadir" or die "no data directory\n";
  my @cnv_filenames =  sort grep (/cdn$|cnv$/, readdir (DATADIR));
  close DATADIR;

  #parse an arbitrary station to get instrument list, all stations must be same instrument list
  if(@cnv_filenames){
      my $cnv_filename = $cnv_filenames[0];
      my $cnv_fullpath_name = "${datadir}${cnv_filename}";
      helper instr_list => sub { state $instr_list = CtdPlot::Model::InstrListFromCNV->new };
      #returns array of structs
      @instruments = $c->instr_list->get($cnv_fullpath_name);
  }
  #get list of selected stations from browser multiselect form
  for my $key (@{$c->req()->params()->names}) {
      my $cnv_filename_array_ref = $c->req()->every_param($key);
      #reset stations selected so it doesn't double count
      @cnv_files_selected=();
      foreach(@$cnv_filename_array_ref){
	  push(@cnv_files_selected,$_);
      }
  };

  foreach my $cnv_file (@cnv_files_selected) {
      my $cnv_fullpath_name = "${datadir}$cnv_file";
      #get data for each cnv file selected by user
      my $instrument = $instruments[1];
      helper cnvdata => sub { state $cnvdata = CtdPlot::Model::getDataFromCNV->new };
      @cnv_info = $c->cnvdata->get_data($cnv_fullpath_name,$instrument);
      push(@all_cnv_info,\@cnv_info);
  }

  #Send data to client 
  $c->stash(fileSelection	=> $cnv_filenames[0]);
  $c->stash(stationslist	=> \@cnv_files_selected);
  $c->stash(stafilelist		=> \@cnv_filenames);
  $c->stash(instrumentlist	=> \@instruments);
  $c->stash(cnv_info		=> \@cnv_info);
  $c->render( template		=> 'index');
};

app->log->debug('Starting application');
app->start;
