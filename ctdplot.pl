#!/usr/bin/env perl
#to test: "./ctd_plot.pl get /"
#or ./ctd_plot.pl get -v '/?filename=ar44027_1db.cnv'
use Mojolicious::Lite -signatures;
use Class::Struct;
use lib qw(lib);
use Storable qw(dclone);
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

struct( Instrument => {
        name => '$',
        number => '$',
        quantity_measured => '$',
        units => '$',
});

struct( Plot => {
        station => '$',
        x_instrument => 'Instrument',
        y_instrument => 'Instrument',
        x_values => '@',
        y_values => '@',
});


my @instruments;
my $instruments = [];
my @x_values;
my @y_values;
my @cnv_files_selected = ();
my $x_axis;
my $y_axis;
my @plots=();

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
      #returns array of structs of instruments
      @instruments = $c->instr_list->get($cnv_fullpath_name);
  }

  #get list of selected stations from browser multiselect form
  for my $key (@{$c->req()->params()->names}) {
      print STDERR "$key:\n";
      my $param_refs = $c->req()->every_param($key);
      #reset stations selected so it doesn't double count
      if($key =~ /file_selection_ID/){
          @cnv_files_selected=();
          foreach (@$param_refs){
	          print STDERR "cnv file: " ;
	          print STDERR ;
	          print STDERR "\n" ;
		  push(@cnv_files_selected,$_);
	  }
      }elsif($key =~ /x_axis/){
          foreach (@$param_refs){
	          print STDERR "x-axis: " ;
	          print STDERR ;
	          print STDERR "\n" ;
		  $x_axis = $_;
	  }
      }elsif($key =~ /y_axis/){
          foreach (@$param_refs){
	          print STDERR "y-axis: " ;
	          print STDERR ;
	          print STDERR "\n" ;
		  $y_axis = $_;
	  }
      }else{
          print STDERR "ERROR" ;
          print STDERR "\n" ;
      }

  };

  my $index=0;
  foreach my $cnv_file (@cnv_files_selected) {
      my $cnv_fullpath_name = "${datadir}$cnv_file";
      $plots[$index] = Plot->new();
      (my $cnv_without_extension = $cnv_file) =~ s/\.[^.]+$//;
      $plots[$index]->station($cnv_without_extension);

      #find x instrument associated with x-axis name given from user
      my $x_axis_instrument = [];
      foreach my $instrument (@instruments){
          if($x_axis eq $instrument->name){
              $x_axis_instrument = $instrument;
              last;
          }
      }
      #print STDERR $x_axis_instrument->name;
      $plots[$index]->x_instrument($x_axis_instrument);
      
      #get x data for instrument selected by user
      helper cnvdata => sub { state $cnvdata = CtdPlot::Model::getDataFromCNV->new };
      @x_values = $c->cnvdata->get_data($cnv_fullpath_name,$x_axis_instrument);
      #$plots[$index]->x_values(dclone \@x_values);
      foreach my $val (@x_values){
	      push @{$plots[$index]->{x_values} }, $val;
      }
      foreach my $val (@{$plots[$index]->{x_values} }){
             print "$val\n";
      }

      
      #find y instrument associated with x-axis name given from user
      my $y_axis_instrument = [];
      foreach my $instrument (@instruments){
          if($y_axis eq $instrument->name){
              $y_axis_instrument = $instrument;
              last;
          }
      }
      #print STDERR $y_axis_instrument->name;
      $plots[$index]->y_instrument($y_axis_instrument);

      #get y data for instrument selected by user
      helper cnvdata => sub { state $cnvdata = CtdPlot::Model::getDataFromCNV->new };
      @y_values = $c->cnvdata->get_data($cnv_fullpath_name,$y_axis_instrument);
      #$plots[$index]->y_values(dclone \@y_values);
      foreach my $val (@y_values){
	      push @{$plots[$index]->{y_values} }, $val;
      }

      $index++;
  }

  foreach my $inst (@plots){
	  print STDERR "Station: ";
	  print STDERR $inst->station;
	  print STDERR "\n";
	  print STDERR "X Instr: ";
	  print STDERR $inst->x_instrument->name;
	  print STDERR "\n";
	  print STDERR "Y Instr: ";
	  print STDERR $inst->y_instrument->name;
	  print STDERR "\n";
	  print STDERR "X Values: ";
	  #my $ary_ref = $inst->x_values;
	  #foreach (@$ary_ref){
	  #foreach (@($inst->x_values)){
	  #    print STDERR;
	  #    print STDERR " ";
	  #}
	  #print STDERR "\nY Values: ";
	  #$ary_ref = $inst->y_values;
	  #foreach (@$ary_ref){
	  #    print STDERR;
	  #    print STDERR " ";
	  #}
  }

  #Send data to client 
  $c->stash(plots		=> \@plots);
  $c->stash(stafilelist		=> \@cnv_filenames);
  $c->stash(instrumentlist	=> \@instruments);
  $c->render(template		=> 'index');
};

app->log->debug('Starting application');
app->start;
