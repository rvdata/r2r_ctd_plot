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
use CtdPlot::Model::getDeltaDataFromCNV;
use CtdPlot::Model::Instrument;
use Array::Utils;

my $datadir = "/home/data/ctd/";
my $index=0;
my $Debug=0;
#if -d option given, override datadir and remove from ARGV before passing to mojo
foreach my $arg (@ARGV) {
    if($ARGV[$index] eq "-d"){
       $datadir = $ARGV[$index+1] . "/";
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
        x_instrument => 'CtdPlot::Model::Instrument',
        y_instrument => 'CtdPlot::Model::Instrument',
        x_values => '@',
        y_values => '@',
});


my @instruments;
my $instruments = [];
my @cnv_info;

#get entire list of cnv files from data dir for user to select from
opendir DATADIR, "$datadir" or die "no data directory\n";
my @cnv_filenames =  sort grep (/cdn$|cnv$/, readdir (DATADIR));
close DATADIR;

#search thru all files to get a complete list of all instruments across all cnv files in the dir
foreach my $cnv_filename (@cnv_filenames){
    my @instrs = CtdPlot::Model::InstrListFromCNV->get("${datadir}${cnv_filename}");
    @instruments = Array::Utils::unique(@instruments, @instrs);
}

get '/' => sub ($c) {
       	$c->render;
} => 'index';

get '/multi' => sub ($c) {
  my @cnv_files_selected=();
  my @x_axes_selected=(); #can be 2 if diff selected
  my @plots=();
  my $x_axis="";
  my $y_axis="";
  #get list of selected stations from browser multiselect form
  for my $key (@{$c->req()->params()->names}) {
      my $param_refs = $c->req()->every_param($key);
      if($key =~ /file_selection_ID/){
          foreach (@$param_refs){ 
		  print "FILE SELECTED: $_\n" if $Debug;
		  push(@cnv_files_selected,$_); 
	  }
      }elsif($key =~ /x_axis/){
          foreach (@$param_refs){ 
		  print "X_AXIS SELECTED: $_\n" if $Debug;
		  push(@x_axes_selected,$_); 
	  }
      }elsif($key =~ /y_axis/){
          foreach (@$param_refs){ 
		  print "Y_AXIS SELECTED: $_\n" if $Debug;
		  $y_axis = $_; 
	  }
      }else{ print STDERR "ERROR\n" ; }

  };

  my $index=0;
  #get selected data set from each cnv file
  my $x_axis_instrument;
  my $y_axis_instrument;
  my $x_axis2_instrument = [];
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
      foreach my $instrument (@instruments){
	      if($x_axes_selected[0] eq $instrument){
		      $x_axis_instrument = CtdPlot::Model::Instrument->new($cnv_fullpath_name, $instrument);
		      last;
	      }
      }
      $plots[$index]->x_instrument($x_axis_instrument);

      #if there's more than one selected, must be diff. Create new Instrument
      if(@x_axes_selected > 1){
	      foreach my $instrument (@instruments){
		      if($x_axes_selected[1] eq $instrument){
			      $x_axis2_instrument = CtdPlot::Model::Instrument->new($cnv_fullpath_name,$instrument);
			      last;
		      }
	      }
	      #overwrite with new instrument
	      $plots[$index]->x_instrument($x_axis2_instrument);
      }

      #find y instrument associated with y-axis name given from user
      foreach my $instrument (@instruments){
          if($y_axis eq $instrument){
	      $y_axis_instrument = CtdPlot::Model::Instrument->new($cnv_fullpath_name, $instrument);
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
      if($Debug){
          foreach my $val (@{$plots[$index]->{x_values}}) {
		  #print "x_val: $val\n";
      	  }
      }
      @{$plots[$index]->{y_values} } = @{ dclone($y_values) };
      if($Debug){
          foreach my $val (@{$plots[$index]->{y_values}}) {
		  #print "y_val: $val\n";
      	  }
      }

      $index++;
  }
  
  my $graph_title;
  if(@x_axes_selected > 1){
	  $graph_title = $x_axis_instrument->{_name} . " - " . $x_axis2_instrument->{_name}  . " vs. " .  $y_axis_instrument->{_name};
  }else{
	  $graph_title = $x_axis_instrument->{_name} . " vs. " .  $y_axis_instrument->{_name};
  }
  my $graph_x_label = $y_axis_instrument->{_property} . " [" . $y_axis_instrument->{_units} . "]";
  my $graph_y_label = $x_axis_instrument->{_property} . " [" . $x_axis_instrument->{_units} . "]";
  

  #Send data to client 
  $c->stash(graph_title		=> $graph_title);
  $c->stash(graph_xlabel	=> $graph_x_label);
  $c->stash(graph_ylabel	=> $graph_y_label);
  $c->stash(plots		=> \@plots);
  $c->stash(stafilelist		=> \@cnv_filenames);
  $c->stash(instrumentlist	=> \@instruments);
  $c->render(template		=> 'multi');
};

get '/single' => sub ($c) {
  #get cnv file name from user, initially equal to ''
  my $filename = $c->param('filename');

  #get list of cnv files
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

