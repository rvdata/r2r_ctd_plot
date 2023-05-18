#!/usr/bin/env perl
#to test: "./ctd_plot.pl get /"
#or ./ctd_plot.pl get -v '/?filename=ar44027_1db.cnv'
use Mojolicious::Lite -signatures;
use Class::Struct;
use lib qw(lib);
use CtdPlot::Model::InstrListFromCNV;
use CtdPlot::Model::CNV2CSV;

my $datadir = "/home/data/armstrong/ctd/";
my $index=0;
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

get '/' => sub ($c) {
  #get cnv file name from user, initially equal to ''
  my $filename = $c->param('filename');

  #get list of cnv files
  my $datadir = "/home/data/armstrong/ctd/";
  opendir DATADIR, "$datadir" or die "no data directory\n";
  my @stafiles =  sort grep (/cdn$|cnv$/, readdir (DATADIR));
  close DATADIR;

  my $input_filename = "${datadir}/${filename}";
  # Helper to lazy initialize and store instrument list object model
  helper instr_list => sub { state $instr_list = CtdPlot::Model::InstrListFromCNV->new };
  #get list of instruments from cnv file
  @instruments = $c->instr_list->get($input_filename);
  
  my $out_file = "public/ctd.dat";
  # Helper to lazy initialize and store csv object model
  helper cnv2csv => sub { state $cnv2csv = CtdPlot::Model::CNV2CSV->new };
  #convert cnv to csv for plotly
  @cnv_info = $c->cnv2csv->convert($input_filename,$out_file,\@instruments);

  $c->stash(fileSelection	=> $filename);
  $c->stash(stafilelist		=> \@stafiles);
  $c->stash(instrumentlist	=> \@instruments);
  $c->stash(cnv_info		=> \@cnv_info);
  $c->render( template		=> 'index');
};

app->start;
