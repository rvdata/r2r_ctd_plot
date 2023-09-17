#!/usr/bin/env perl
#to test: "./ctd_plot.pl get /"
#or ./ctd_plot.pl get -v '/?filename=ar44027_1db.cnv'
use Mojolicious::Lite -signatures;
use Class::Struct;
use lib qw(lib);
use Storable qw(dclone);
use CtdPlot::Model::InstrListFromCNV;
use CtdPlot::Model::InstrListFromCNV2;
use CtdPlot::Model::CNV2CSV;
use CtdPlot::Model::getDataFromCNV;
use CtdPlot::Model::getDeltaDataFromCNV;
use CtdPlot::Model::Instrument;
use Array::Utils;

my $datadir = "/home/data/ctd/";
my $index=0;
my $Debug=1;
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


my @instruments_multi;
my @instruments_single;
my $instruments = [];
my @cnv_info;

#get entire list of cnv files from data dir for user to select from
opendir DATADIR, "$datadir" or die "no data directory\n";
my @cnv_filenames =  sort grep (/cdn$|cnv$/, readdir (DATADIR));
close DATADIR;

#search thru all files to get a complete list of all instruments across all cnv files in the dir
foreach my $cnv_filename (@cnv_filenames){
    my @instrs = CtdPlot::Model::InstrListFromCNV->get("${datadir}${cnv_filename}");
    @instruments_multi = Array::Utils::unique(@instruments_multi, @instrs);
}
@instruments_multi = sort(@instruments_multi);

get '/' => sub ($c) {
       	$c->render;
} => 'index';

get '/multi' => sub ($c) {
  print "\n\n";
  if($Debug){
      foreach my $instrument (@instruments_multi){
	  print "INSTRUMENT: $instrument\n";
      }
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
  my $x_axis2_instrument;
  my $graph_title;
  my $graph_x_label;
  my $graph_y_label;
  my $graph_x_property;
  my $graph_y_property;
  my $graph_y2_property;
  my $graph_xlabel_set = 0;
  my $graph_x2label_set = 0;
  my $graph_ylabel_set = 0;
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
      foreach my $instrument (@instruments_multi){
	      if($x_axes_selected[0] eq $instrument){
		      $x_axis_instrument = CtdPlot::Model::Instrument->new($cnv_fullpath_name, $instrument);
                      print "x-instrument: $instrument\n" if $Debug;
                      print "x-instrument exists: $x_axis_instrument->{_exists}\n" if $Debug;
		      last;
	      }
      }
      $plots[$index]->x_instrument($x_axis_instrument);

      #if there's more than one selected, must be diff. Create new Instrument
      if(@x_axes_selected > 1){
	      foreach my $instrument (@instruments_multi){
		      if($x_axes_selected[1] eq $instrument){
                              print "x2-instrument: $instrument\n" if $Debug;
			      $x_axis2_instrument = CtdPlot::Model::Instrument->new($cnv_fullpath_name,$instrument);
			      last;
		      }
	      }
	      #overwrite with new instrument
	      #$plots[$index]->x_instrument($x_axis2_instrument);
      }

      #find y instrument associated with y-axis name given from user
      foreach my $instrument (@instruments_multi){
          if($y_axis eq $instrument){
              print "y-instrument: $instrument\n" if $Debug;
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

  
      if(@x_axes_selected > 1){
          if($y_axis_instrument->{_exists} && !$graph_ylabel_set){ 
		  $graph_ylabel_set = 1; 
		  $graph_x_property = $y_axis_instrument->{_name};
		  $graph_x_label = $graph_x_property . " [" . $y_axis_instrument->{_units} . "]";
          }
          if($x_axis_instrument->{_exists} && !$graph_xlabel_set && $x_axis2_instrument->{_exists}){ 
		  $graph_xlabel_set = 1; 
		  $graph_y_property = $x_axis_instrument->{_name};
		  $graph_y2_property = $x_axis2_instrument->{_name};
		  $graph_y_label = $graph_y_property . " [" . $x_axis_instrument->{_units} . "]";
          }else{
		  $x_axis_instrument->{_exists} = 0;
	  }
      }else{
          if($y_axis_instrument->{_exists} && !$graph_ylabel_set){ 
		  $graph_ylabel_set = 1; 
		  $graph_x_property = $y_axis_instrument->{_name};
		  $graph_x_label = $graph_x_property . " [" . $y_axis_instrument->{_units} . "]";
          }
          if($x_axis_instrument->{_exists} && !$graph_xlabel_set){ 
		  $graph_xlabel_set = 1; 
		  $graph_y_property = $x_axis_instrument->{_name};
		  $graph_y_label = $graph_y_property . " [" . $x_axis_instrument->{_units} . "]";
          }
      }
      $index++;
  }



  if(@x_axes_selected > 1){
      my $all_data_exists = 0;
      foreach my $plot (@plots) { 
	  if( $plot->x_instrument->{_exists} && $plot->y_instrument->{_exists} ) { 
		  $all_data_exists = 1; 
		  last;
	  }
      }
      if($all_data_exists){
	  $graph_title = "$graph_x_property vs.  ($graph_y2_property  - $graph_y_property)";
      }else{
	  $graph_x_label = "N/A"; 
	  $graph_y_label = "N/A"; 
	  $graph_title = "Data Not Available";
      }
  } else {
      if(!$graph_ylabel_set || !$graph_xlabel_set){ 
	  $graph_x_label = "N/A"; 
	  $graph_y_label = "N/A"; 
	  $graph_title = "Data Not Available";
      }else{
	  $graph_title = $graph_x_property . " vs. " .  $graph_y_property;
      }
  }

  #Send data to client 
  $c->stash(graph_title		=> $graph_title);
  $c->stash(graph_xlabel	=> $graph_x_label);
  $c->stash(graph_ylabel	=> $graph_y_label);
  $c->stash(plots		=> \@plots);
  $c->stash(stafilelist		=> \@cnv_filenames);
  $c->stash(instrumentlist	=> \@instruments_multi);
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
  helper instr_list => sub { state $instr_list = CtdPlot::Model::InstrListFromCNV2->new };
  #get list of instruments from cnv file
  @instruments_single = $c->instr_list->get($input_filename);
  if($Debug){
      foreach my $instrument (@instruments_single){
	  print "INSTRUMENT: " . $instrument->name . "\n";
      }
  }

  
  my $out_file = "public/ctd.dat";
  # Helper to lazy initialize and store csv object model
  helper cnv2csv => sub { state $cnv2csv = CtdPlot::Model::CNV2CSV->new };
  #convert cnv to csv for plotly
  @cnv_info = $c->cnv2csv->convert($input_filename,$out_file,\@instruments_single);

  $c->stash(fileSelection	=> $filename);
  $c->stash(stafilelist		=> \@stafiles);
  $c->stash(instrumentlist	=> \@instruments_single);
  $c->stash(cnv_info		=> \@cnv_info);
  $c->render( template		=> 'single');
};

app->start;

