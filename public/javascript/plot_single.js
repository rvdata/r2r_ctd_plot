//20200629 sharding colors to match gnuplot
//20200701 sharding carved out graph parameters as objects
//20200702 sharding added plot4 salinity vs temp
//20200702 sharding added time plots
//20200720 sharding replaced all "Class" definitions with function calls for Safari
//20200720 sharding rewrote Math.max() function call to please Safari
//20200722 sharding hard-coded all default plots

var Instrument = function() {
	this.name;
	this.units;
	this.variable;
	this.addName = function(name){ this.name = name; }
	this.addUnits = function(units){ this.units = units; }
	this.addVariable = function(variable){ this.variable = variable; }
}

instrument = [];

function onLoadFunction() {
	//turn off loader
	document.getElementById("loader").style.display = "none";
        document.getElementById("myDiv").style.display = "block";
}

function Line(color) {
	this.width = 1;
	this.color = '';
};


var Trace = function(x, y, color, name) {
	this.x = x;
	this.y = y;
	this.name = name;
	this.type = 'scatter';
	this.line = new Line(color);
};

var TraceTime = function(y, colorNum, name) {
	this.y = y;
	this.name = name;
	this.type = 'scatter';
	this.line = new Line(colorNum);
};

var Graph = function(title, xLabel, yLabel) {
	this.title = title;
	this.xLabel = xLabel;
	this.yLabel = yLabel;
        this.x=[];
        this.y=[];
        this.numXDataSets=0;
        this.numYDataSets=0;
        this.traceName=[];
        this.pushXData = function(data) {
                this.x[this.numXDataSets] = data;
                this.numXDataSets++;
        };
        this.createNewTrace = function(traceName) {
                this.traceName[this.numYDataSets] = traceName;
	};
        this.pushTraceData = function(data) {
                this.y[this.numYDataSets] = data;
                this.numYDataSets++;
        };
        this.sizeYData = function() {
		return this.x[0].length;
        };
        this.maxYValue = function() {
		var maxValue=0;
		for(index=0; index <  this.numYDataSets; index++){
			//var newMaxValue = Math.max(...this.y[index]);
			//need this for Safari, it doesn't like "...this.y"
			var newMaxValue = Math.max.apply(null, this.y[index].map(Math.abs));
			if( newMaxValue > maxValue ){
				maxValue = newMaxValue;
			}
		}
		return maxValue;
        };
};

var Layout = function(title, xLabel, yLabel) {
	this.width = 600;
	this.height = 550;
	this.automargin = true;
	this.margin = {
		l:50,
		r:50,
		b:50,
		t:80,
		pad:4
	};
	this.hovermode ='closest';
	this.title = "";
	this.showlegend = true;
	this.xaxis;
	this.yaxis;
	this.paper_bgcolor='lightblue'
	this.legend = {
		x: 1,
		xanchor: 'right',
		y: 1
	};
	this.title = title;
	this.xaxis = {
		title: xLabel,
		showgrid: true,
		zeroline: true,
		mirror: 'ticks',
		gridcolor: '#bdbdbd',
		gridwidth: 2,
		zerolinecolor: '#969696',
		zerolinewidth: 4,
		linecolor: '#636363',
		autotick: true,
		ticks: 'inside',
		tick0: 0,
		dtick: 1,
		ticklen: 6,
		tickwidth: 2
	};
	this.yaxis = {
		title: yLabel,
		showgrid: true,
		zeroline: true,
		showline: true,
		mirror: 'ticks',
		gridcolor: '#bdbdbd',
		gridwidth: 2,
		ticks: 'inside',
		zerolinecolor: '#969696',
		zerolinewidth: 4,
		tickwidth: 2,
		ticklen: 6,
		linecolor: '#636363'
	};
};

var LayoutTime = function(title, xLabel, yLabel, deltaT) {
	this.width = 600;
	this.height = 550;
	this.automargin = true;
	this.margin = {
		l:50,
		r:50,
		b:50,
		t:80,
		pad:4
	};
	this.hovermode ='closest';
	this.title = "";
	this.showlegend = true;
	this.xaxis;
	this.yaxis;
	this.paper_bgcolor='lightblue'
	this.legend = {
		x: 1,
		xanchor: 'right',
		y: 1
	};
	this.title = title;
	this.xaxis = {
		title: xLabel,
		showgrid: true,
		zeroline: true,
		mirror: 'ticks',
		gridcolor: '#bdbdbd',
		gridwidth: 2,
		zerolinecolor: '#969696',
		zerolinewidth: 4,
		linecolor: '#636363',
		autotick: false,
		ticks: 'inside',
		tick0: 0,
		dtick: deltaT,
		ticklen: 6,
		tickwidth: 2
	};
	this.yaxis = {
		title: yLabel,
		showgrid: true,
		zeroline: true,
		showline: true,
		mirror: 'ticks',
		gridcolor: '#bdbdbd',
		gridwidth: 2,
		ticks: 'inside',
		zerolinecolor: '#969696',
		zerolinewidth: 4,
		tickwidth: 2,
		ticklen: 6,
		linecolor: '#636363'
	};
};

function displayMultiSelect() {
	//display multi select menu
	var x_axis_values; //active instrument
	var y_axis_values; //list of all instruments selected
	$x_axis_values = [];
	$y_axis_values = []; 

	// multi-Selection form for instruments
        $(document).ready(function(){
		$('#x_axis_ID' ).multi();
	});
	// Selection form
	$( '#x_axis_ID' ).multi({
		non_selected_header: 'Variables',
		selected_header: 'Selected Variable'
	});
	// Selection form
	$( '#x_axis_ID' ).multi({
		// enable search
		enable_search: true,
		// placeholder of search input
		search_placeholder: 'Search...'
	});


        // multi-Selection form for instruments
	$(document).ready(function(){
		$('#y_axis_ID' ).multi();
	});
	// Selection form
	$( '#y_axis_ID' ).multi({
		non_selected_header: 'Variables',
		selected_header: 'Selected Variables'
	});
	// Selection form
	$( '#y_axis_ID' ).multi({
		// enable search
		enable_search: true,
		// placeholder of search input
		search_placeholder: 'Search...'
	}); 

}; 

function makeplot() {
	//grap csv data and hand off to plotly.js
	/* turn loader on */
        document.getElementById("loader").style.display = "";
        document.getElementById("myDiv").style.display = "";

	Plotly.d3.csv("ctd.dat", function(data){
		processDefaultData(data)
	}); 
}; 

function makeCustomPlot() {
	/* turn loader on */
        document.getElementById("loader").style.display = "";
        document.getElementById("myDiv").style.display = "";

	Plotly.d3.csv("../ctd.dat", function(data){
		processCustomData(data)
	}); 
}; 

function processDefaultData(allRows) {
	//most graphs use prDM depth as the y-axis data set.
	//However since this is the independent variable, it's normally plotted along x-axis.
	//But Here the data is described as Y data so plotly will use it as y-data.
	//But if it's a time-based plot, the data are reversed so time is plotted along x-axis.
	var yData = [];
	var yVariable = 'prDM';
	var rawData = [];
	for (var i=0; i<allRows.length; i++) {
		row = allRows[i];
		rawData.push( row[yVariable] );
	}
	yData[yVariable] =  rawData;

//	console.log("prdm[" + yData['prDM'] + ":");
        var graph;	
	var title;
	var xLabel;
	var yLabel;
	var plot_div;
	var xData = [];
	var plot=1;
	var xVariables = [];

	//check if time plot
	var isTimePlotChecked = document.getElementById("time_radio_id").checked;

	/*----------------------Depth vs Temperature-----------------------*/
	xVariables = [ 't090C', 't190C' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	if(isTimePlotChecked){
		//omit y data and put xVariable onto x-axis
		//ignore original y-data
		title = "Temperature vs Time";
		xLabel = "Time";
		yLabel = "";

		if( instrument[xVariables[0]] ) {
			yLabel = yLabel + xVariables[0];
			if( instrument[xVariables[1]] ) {
				yLabel = yLabel + ", " + xVariables[1];
			}
			yLabel = yLabel + " [" + instrument[xVariables[0]].units + "]";
		}


		graph = new Graph(title, xLabel, yLabel);


		if( instrument[xVariables[0]] ) {
			graph.pushXData( xData[instrument[xVariables[0]].name] );
			graph.createNewTrace( instrument[xVariables[0]].name );
			graph.pushTraceData( xData[instrument[xVariables[0]].name] );
		}

		if( instrument[xVariables[1]] ) {
			graph.pushXData( xData[instrument[xVariables[1]].name] );
			graph.createNewTrace( instrument[xVariables[1]].name );
			graph.pushTraceData( xData[instrument[xVariables[1]].name] );
		}

		plot_div = "plot" + plot++;
		makePlotlyGraphTime(graph,plot_div); 
	} else {
		//reverse x and y data 
		title = "Depth vs Temperature";
		xLabel = "";
		if( instrument[xVariables[0]] ) {
			xLabel = xLabel + xVariables[0];
		}
		if( instrument[xVariables[1]] ) {
			xLabel = xLabel + ", " + xVariables[1];
		}
		if( instrument[xVariables[0]] ) {
			xLabel = xLabel + " [" + instrument[xVariables[0]].units + "]";
		}
		yLabel = yVariable + " [" + instrument[yVariable].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		//note here reverse x and y data to put depth (independent variable) on y-axis
		graph.pushXData(yData[yVariable]);
		xVariables.forEach(pushDataOntoGraph); 
		function pushDataOntoGraph(xVariable, index, array) {
				if( instrument[xVariable] ){ 
					graph.createNewTrace(xVariable);
					graph.pushTraceData(xData[xVariable]);
				}
		}
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	}

	/*----------------------Depth vs Salinity-----------------------*/
	xVariables = [ 'sal00', 'sal11' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	//console.log("sal[" + xData['sal11'] + "]=");
	if(isTimePlotChecked){
		//omit y data and put x-data onto x-axis
		title = "Salinity vs Time";
		xLabel = "Time";
		yLabel = xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(xData['sal00']);
		graph.pushXData(xData['sal11']);
		graph.createNewTrace('sal00');
		graph.pushTraceData(xData['sal00']);
		graph.createNewTrace('sal11');
		graph.pushTraceData(xData['sal11']);
		plot_div = "plot" + plot++;
		makePlotlyGraphTime(graph,plot_div); 
	} else {
		title = "Depth vs Salinity";
		xLabel = "";
		if( instrument[xVariables[0]] ) {
			xLabel = xLabel + xVariables[0];
		}
		if( instrument[xVariables[1]] ) {
			xLabel = xLabel + ", " + xVariables[1];
		}
		xLabel = xLabel + " [" + instrument[xVariables[0]].units + "]";
		yLabel = yVariable + " [" + instrument[yVariable].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(yData[yVariable]);
		xVariables.forEach(pushDataOntoGraph); 
		function pushDataOntoGraph(xVariable, index, array) {
				if( instrument[xVariable] ){ 
					graph.createNewTrace(xVariable);
					graph.pushTraceData(xData[xVariable]);
				}
		}
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	}


	/*----------------------Depth vs Oxygen-----------------------*/
	xVariables = [ 'sbeox0ML_L' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	if(isTimePlotChecked){
		//omit y data and put x-data onto x-axis
		title = "Oxygen vs Time";
		xLabel = "Time";
		yLabel = xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(xData['sbeox0ML_L']);
		graph.createNewTrace('sbeox0ML_L');
		plot_div = "plot" + plot++;
		makePlotlyGraphTime(graph,plot_div); 
	} else {
		title = "Depth vs Oxygen";
		xLabel = xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
		yLabel = yVariable + " [" + instrument[yVariable].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(yData[yVariable]);
		xVariables.forEach(pushDataOntoGraph); 
		function pushDataOntoGraph(xVariable, index, array) {
				if( instrument[xVariable] ){ 
					graph.createNewTrace(xVariable);
					graph.pushTraceData(xData[xVariable]);
				}
		}
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	}

	/*----------------------Temp vs Salinity-----------------------*/
	/*----------------------Temp is now yVar-----------------------*/
	var yVariable = 't090C';
	var rawData = [];
	for (var i=0; i<allRows.length; i++) {
		row = allRows[i];
		rawData.push( row[yVariable] );
	}
	yData[yVariable] =  rawData;

	xVariables = [];
	xVariables = [ 'sal00' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	title = "Temp vs Salinity";
	xLabel = xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
	yLabel = yVariable + " [" + instrument[yVariable].units + "]";
	graph = new Graph(title, xLabel, yLabel);
	graph.pushXData(yData[yVariable]);
	xVariables.forEach(pushDataOntoGraph); 
	function pushDataOntoGraph(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			graph.createNewTrace(xVariable); 
			graph.pushTraceData(xData[xVariable]);
		}
	}
	plot_div = "plot" + plot++;
	makePlotlyGraph(graph,plot_div); 


	/* reset y=prDM */
	var yVariable = 'prDM';
	var rawData = [];
	for (var i=0; i<allRows.length; i++) {
		row = allRows[i];
		rawData.push( row[yVariable] );
	}
	yData[yVariable] =  rawData;
	/*----------------------Temperature Diff-------------------*/
	xVariables = [ 't090C', 't190C' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	//make sure there are 2 data sets
	title = "Depth vs Temperature Difference";
	xLabel = xVariables[0];
	yLabel = yVariable;
	//make sure there are two variables
	if( instrument[xVariables[1]] ) {
		var diff=[];
		diff = xData[xVariables[0]].map(function (num, idx) {
			return num - xData[xVariables[1]][idx]; 
		});
		traceName = xVariables[0] + " - " + xVariables[1];
		xLabel = traceName + " [" + instrument[xVariables[0]].units + "]";
		yLabel = yVariable + " [" + instrument[yVariable].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(yData[yVariable]);
		graph.createNewTrace(traceName);
		graph.pushTraceData(diff);
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	} else {
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(0);
		graph.createNewTrace("void");
		graph.pushTraceData(0);
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	}


	/*----------------------Conductivity Diff-------------------*/
	xVariables = [ 'c0S_m', 'c1S_m' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	//make sure there are two data sets
	title = "Depth vs Conductivity Difference";
	xLabel = xVariables[0];
	yLabel = yVariable;
		if( instrument[xVariables[1]] ) {
			var diff=[];
			diff = xData[xVariables[0]].map(function (num, idx) {
				return num - xData[xVariables[1]][idx]; 
			});
			traceName = xVariables[0] + " - " + xVariables[1];
			xLabel = traceName + " [" + instrument[xVariables[0]].units + "]";
			yLabel = yVariable + " [" + instrument[yVariable].units + "]";
			graph = new Graph(title, xLabel, yLabel);
			graph.pushXData(yData[yVariable]);
			graph.createNewTrace(traceName);
			graph.pushTraceData(diff);
		} else {
			graph = new Graph(title, xLabel, yLabel);
			graph.pushXData(0);
			graph.createNewTrace("void");
			graph.pushTraceData(0);
		}
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 

	/*----------------------Transmissometer-----------------------*/
	xVariables = [ 'CStarTr0' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	if(isTimePlotChecked){
		//omit y data and put x-data onto x-axis
		title = "Transmissometer vs Time";
		xLabel = "Time";
		yLabel = "";
		if( instrument[xVariables[0]] ) {
			yLabel = yLabel + xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
		}
		graph = new Graph(title, xLabel, yLabel);
		if( instrument[xVariables[0]] ) {
			graph.pushXData(xData['CStarTr0']);
			graph.createNewTrace('CStarTr0');
		} else {
			graph.pushXData(0);
			graph.createNewTrace('void');
		}
		plot_div = "plot" + plot++;
		makePlotlyGraphTime(graph,plot_div); 
	} else {
		title = "Depth vs Transmissometer";
		xLabel = xVariables[0];
		if( instrument[xVariables[0]] ) {
			xLabel = xLabel + " [" + instrument[xVariables[0]].units + "]";
		}
		yLabel = yVariable + " [" + instrument[yVariable].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(yData[yVariable]);
		xVariables.forEach(pushDataOntoGraph); 
		function pushDataOntoGraph(xVariable, index, array) {
			if( instrument[xVariable] ){ 
				graph.createNewTrace(xVariable);
				graph.pushTraceData(xData[xVariable]);
			}
		}
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	}


	/*----------------------Environmental-----------------------*/
	xVariables = [ 'flECO_AFL', 'turbWETntu0', 'wetCDOM' ];
	console.log("xvars=" + xVariables);
	console.log("plot=" + plot);
	xVariables.forEach(populateData); 
	function populateData(xVariable, index, array) {
		if( instrument[xVariable] ){ 
			rawData = [];
			for (var i=0; i<allRows.length; i++) {
				row = allRows[i];
				rawData.push( row[xVariable] );
			}
			xData[xVariable] =  rawData;
		}
	} 
	if(isTimePlotChecked){
		//omit y data and put xVariable onto x-axis
		//ignore original y-data
		title = "Fluorometer, Turbidity vs Time";
		xLabel = "Time";
		yLabel = "";


		if( instrument[xVariables[0]] ) {
			yLabel += xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
		}
		if( instrument[xVariables[1]] ) {
			yLabel += "," + xVariables[1] + " [" + instrument[xVariables[1]].units + "]";
		}
		if( instrument[xVariables[2]] ) {
			yLabel += "," + xVariables[2] + " [" + instrument[xVariables[2]].units + "]";
		}

		graph = new Graph(title, xLabel, yLabel);
		if( xData['flECO_AFL'] ) {
			graph.pushXData(xData['flECO_AFL']);
			graph.createNewTrace("flECO_AFL");
			graph.pushTraceData(xData['flECO_AFL']);
		} else if( xData['turbWETntu0'] ){
			graph.pushXData(xData['turbWETntu0']);
			graph.createNewTrace("turbWETntu0");
			graph.pushTraceData(xData['turbWETntu0']);
		} else if( xData['wetCDOM'] ) {
			graph.pushXData(xData['wetCDOM']);
			graph.createNewTrace("wetCDOM");
			graph.pushTraceData(xData['wetCDOM']);
		} else {
			console.log("not data found");
			graph.pushXData(0);
			graph.createNewTrace("void");
			graph.pushTraceData(0);
		}
		plot_div = "plot" + plot++;
		makePlotlyGraphTime(graph,plot_div); 
	} else {
		title = "Depth vs Fluorometer, Turbidity";
		xLabel = "";
		if( instrument[xVariables[0]] ) {
			xLabel = xLabel + xVariables[0] + " [" + instrument[xVariables[0]].units + "]";
		}
		if( instrument[xVariables[1]] ) {
			xLabel = xLabel + " " + xVariables[1] + " [" + instrument[xVariables[1]].units + "]";
		}
		if( instrument[xVariables[2]] ) {
			xLabel = xLabel + " " + xVariables[2] + " [" + instrument[xVariables[2]].units + "]";
		}
		yLabel = yVariable + " [" + instrument[yVariable].units + "]";
		graph = new Graph(title, xLabel, yLabel);
		graph.pushXData(yData[yVariable]);
		xVariables.forEach(pushDataOntoGraph); 
		function pushDataOntoGraph(xVariable, index, array) {
			if( instrument[xVariable] ){ 
				graph.createNewTrace(xVariable);
				graph.pushTraceData(xData[xVariable]);
			}
		}
		plot_div = "plot" + plot++;
		makePlotlyGraph(graph,plot_div); 
	}


        var overlayID = document.getElementById("overlay");
	document.getElementById("loader").style.display = "none";
	overlayID.style.display="none";
}


function processCustomData(allRows) {
        //get list of x-axis variables from multi-selection drop-down list
        x_axis_values = $("#x_axis_ID").val();
        if (x_axis_values == "") {
                alert("Instrument must be filled out");
                return false;
        }
        $.each(x_axis_values, function (key, value) {
                x_axis_values.push(value);
        });

        //get list of y-axis variables from multi-selection drop-down list
        y_axis_values = $("#y_axis_ID").val();
        if (y_axis_values == "") {
                alert("Instrument must be filled out");
                return false;
        }
        $.each(y_axis_values, function (key, value) {
                y_axis_values.push(value);
        });


	//Get x data from cnv file
       var xData = [];
       for (index = 0; index < (x_axis_values.length / 2); index++) {
	       var xVariable = instrument[x_axis_values[index]].name;
	       var rawData = [];
	       for (var i=0; i<allRows.length; i++) {
		       row = allRows[i];
		       rawData.push( row[xVariable] );
	       }
	       xData[xVariable] =  rawData;
       }
	//Get y data from cnv file
       var yData = [];
	var isTimePlot = false;
	for (index = 0; index < (y_axis_values.length / 2); index++) {
		if( y_axis_values[index] == "time" ){
			isTimePlot = true;
		}
		var yVariable = instrument[y_axis_values[index]].name;
		var rawData = [];
		for (var i=0; i<allRows.length; i++) {
			row = allRows[i];
			rawData.push( row[yVariable] );
		}
		yData[yVariable] =  rawData;
	}


        var graph;	
	var title;
	var xLabal;
	var yLabal;


	title = instrument[x_axis_values[0]].variable + " vs " + instrument[y_axis_values[0]].variable;
	xLabel = instrument[x_axis_values[0]].variable + " [" + instrument[x_axis_values[0]].units + "]";
	yLabel = instrument[y_axis_values[0]].variable + " [" + instrument[y_axis_values[0]].units + "]";
        graph = new Graph(title, yLabel, xLabel);
	for (index = 0; index < (x_axis_values.length / 2); index++) {
		graph.pushXData(xData[x_axis_values[index]]);
	}

	// If Delta plot
	if (document.getElementById('diff_id').checked) { 
		array0 = yData[y_axis_values[0]];
		array1 = yData[y_axis_values[1]];
		var diff=[];
		diff = array0.map(function (num, idx) {
			return num - array1[idx]; 
		});
		graph.createNewTrace("Difference");
		graph.pushTraceData(diff);
		makePlotlyGraph(graph,custom_plot); 
	} else {
		if(isTimePlot){
			for (index = 0; index < (x_axis_values.length / 2); index++) {
				graph.createNewTrace(instrument[x_axis_values[index]].name);
				graph.pushTraceData(yData[x_axis_values[index]]);
			}
			makePlotlyGraphTime(graph,custom_plot); 
		} else {
			for (index = 0; index < (y_axis_values.length / 2); index++) {
				graph.createNewTrace(instrument[y_axis_values[index]].name);
				graph.pushTraceData(yData[y_axis_values[index]]);
			}
			makePlotlyGraph(graph,custom_plot); 
		}
	}

        var overlayID = document.getElementById("overlay");
	document.getElementById("loader").style.display = "none";
	overlayID.style.display="none";
}

function makePlotlyGraph(graph,div_id){
	//makes a plot from a Graph object.
	//Note this function will call Trace() which swaps
	//x and y data because depth is plotted along y-axis even though
	//it's actually the independent variable.

	var trace=[];
	for(index=0; index <  graph.numYDataSets; index++){
		//create a Trace object for each y-data set. 
		//NOTE X and Y VALUES ARE SWAPPPED HERE.
		trace[index] = new Trace(graph.y[index], graph.x[0], index, graph.traceName[index]);
	}

        var layout = new Layout(graph.title, graph.xLabel, graph.yLabel);

	var data = [];
	for(index=0; index < trace.length ; index++){
		data.push(trace[index]);
	}
	Plotly.newPlot(div_id, data, layout);
        //var overlayID = document.getElementById("overlay");
	//document.getElementById("loader").style.display = "none";
	//overlayID.style.display="none";
};

function makePlotlyGraphTime(graph,div_id){
	//for time-based graphs, this function calls 
	//TraceTime() instead of Trace() above.
	//See the description of makePlotlyGraph() and Trace().
	//the y data is removed in the
	//TraceTime() function call below.
	var trace=[];
	for(index=0; index <  graph.numXDataSets; index++){
		//create a Trace object for each x-data set. 
		//NOTE Y DATA ARE IGNORED HERE.
		trace[index] = new TraceTime( graph.x[index], index, graph.traceName[index]);
	}

	//Create Graph Layout
	var numVertGridLines=10;
	var deltaT =  Math.round( ( graph.sizeYData() ) / numVertGridLines );
        var layout = new LayoutTime(graph.title, graph.xLabel, graph.yLabel, deltaT);

	//collect all traces into one array
	var data = [];
	for(index=0; index < trace.length ; index++){
		data.push(trace[index]);
	}
	Plotly.newPlot(div_id, data, layout);
//        var overlayID = document.getElementById("overlay");
//	document.getElementById("loader").style.display = "none";
//	overlayID.style.display="none";
};
