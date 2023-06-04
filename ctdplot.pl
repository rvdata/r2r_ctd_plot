#!/usr/bin/env perl
#to test: "./ctd_plot.pl get /"
#or ./ctd_plot.pl get -v '/?filename=ar44027_1db.cnv'
use Mojolicious::Lite -signatures;
use Class::Struct;
use lib qw(lib);
use Storable qw(dclone);
#use Mojo::JSON qw(decode_json encode_json);
#use JSON;
use CtdPlot::Model::InstrListFromCNV;
use CtdPlot::Model::CNV2CSV;
use CtdPlot::Model::getDataFromCNV;
use CtdPlot::Model::getDeltaDataFromCNV;

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
my @cnv_info;
get '/' => sub ($c) {
       	$c->render;
} => 'index';

get '/multi' => sub ($c) {
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

  my @cnv_files_selected=();
  my @x_axes_selected=(); #can be 2 if diff selected
  my @plots=();
  my $x_axis="";
  my $y_axis="";
  #get list of selected stations from browser multiselect form
  for my $key (@{$c->req()->params()->names}) {
      my $param_refs = $c->req()->every_param($key);
      if($key =~ /file_selection_ID/){
          foreach (@$param_refs){ push(@cnv_files_selected,$_); }
      }elsif($key =~ /x_axis/){
          foreach (@$param_refs){ 
		  push(@x_axes_selected,$_); 
	  }
      }elsif($key =~ /y_axis/){
          foreach (@$param_refs){ $y_axis = $_; }
      }else{ print STDERR "ERROR\n" ; }

  };

  my $index=0;
  #get selected data set from each cnv file
  foreach my $cnv_file (@cnv_files_selected) {
      my $x_values;
      my $y_values;
      my $cnv_fullpath_name = "${datadir}$cnv_file";
      $plots[$index] = Plot->new();
      #remove .cnv extension just to shorten name for plotly label
      (my $cnv_without_extension = $cnv_file) =~ s/\.[^.]+$//;
      #create a plot object for each station
      $plots[$index]->station($cnv_without_extension);

      #search instrument list for instrument selected by user, used for plotting x-axis
      my $x_axis_instrument = [];
      foreach my $instrument (@instruments){
	      if($x_axes_selected[0] eq $instrument->name){
		      $x_axis_instrument = $instrument;
		      last;
	      }
      }
      $plots[$index]->x_instrument($x_axis_instrument);

      #if there's more than one selected, must be diff. Create new Instrument
      my $x_axis2_instrument = [];
      if(@x_axes_selected > 1){
	      foreach my $instrument (@instruments){
		      if($x_axes_selected[1] eq $instrument->name){
			      $x_axis2_instrument = $instrument;
			      last;
		      }
	      }
	      my $diff_instr = Instrument->new();
	      my $instrument_name = "$x_axes_selected[0] - $x_axes_selected[1]";
              $diff_instr->name($instrument_name);
	      $diff_instr->units($x_axis_instrument->units);
	      $diff_instr->quantity_measured($x_axis_instrument->quantity_measured);
	      push(@instruments,$diff_instr);
	      $plots[$index]->x_instrument($diff_instr);
      }

      

      #find y instrument associated with y-axis name given from user
      my $y_axis_instrument = [];
      foreach my $instrument (@instruments){
          if($y_axis eq $instrument->name){
              $y_axis_instrument = $instrument;
              last;
          }
      }
      $plots[$index]->y_instrument($y_axis_instrument);

      helper cnvdata => sub { state $cnvdata = CtdPlot::Model::getDataFromCNV->new };
      helper cnvdeltadata => sub { state $cnvdata = CtdPlot::Model::getDeltaDataFromCNV->new };
      #get x,y data for instrument selected by user
      if(@x_axes_selected > 1){
	      ($x_values,$y_values) = $c->cnvdeltadata->get_delta_data($cnv_fullpath_name,$x_axis_instrument,$x_axis2_instrument,$y_axis_instrument);
      } else {
	      ($x_values,$y_values) = $c->cnvdata->get_data($cnv_fullpath_name,$x_axis_instrument,$y_axis_instrument);
      }

      @{$plots[$index]->{x_values} } = @{ dclone($x_values) };
      @{$plots[$index]->{y_values} } = @{ dclone($y_values) };

      $index++;
  }
  

  #Send data to client 
  $c->stash(plots		=> \@plots);
  $c->stash(stafilelist		=> \@cnv_filenames);
  $c->stash(instrumentlist	=> \@instruments);
  $c->render(template		=> 'multi');
};

get '/single' => sub ($c) {
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
  $c->render( template		=> 'single');
};

app->start;
