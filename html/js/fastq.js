var chartWidth;

$(document).ready(function(){
	var graphConts = $(".cont-item");
	var listitems = $(".list-item");
	var chartClose = $(".chart-close"); 
	//add ids to map items to graphs
	for(i=0;i<graphConts.length;i++){
		var thislistitem = listitems[i];
		var thisgraph = graphConts[i];
		var thischartClose = chartClose[i];
		thislistitem.id = "item_"+i;
		thisgraph.id = "graph_"+i;
		thischartClose.id = "close_"+i;
	};
	//click listener - when item is clicked, show graph
	$(listitems).click(function(){
		var idx = this.id.split("_")[1];
		var graph = document.getElementById("graph_"+idx);
		var close = document.getElementById("close_"+idx);
		var item = document.getElementById("item_"+idx);
		toggleGraph(graph,close,item);
	});
	//click listener - when chart close button is clicked, hide graph
	$(chartClose).click(function(){
		var idx = this.id.split("_")[1];
		var graph = document.getElementById("graph_"+idx);
		var close = document.getElementById("close_"+idx);
		var item = document.getElementById("item_"+idx);
		toggleGraph(graph,close,item);
	});
	chartWidth = graphConts[0].offsetWidth-25;
	graphConts.hide();
	connect();
});

function toggleGraph(graph,close,item){
	var $graph = $(graph);
	var isvisible = $graph.is(":visible");
	if(isvisible){
		$(item).removeClass("fa-rotate-45");
		$(item).addClass("fa-rotate-0");
		$graph.hide();
	}else{
		console.log(item);
		$(item).removeClass("fa-rotate-0");
		$(item).addClass("fa-rotate-45");
		$graph.show();
		$("#main-cont").prepend($graph);
	}
}

function connect(){
	ws = new WebSocket("ws://localhost:50889");
	ws.binaryType="arraybuffer";
	
	sendCmd = function(msg){
		ws.send(serialize(JSON.stringify(msg)));
	}

	ws.onopen = function(){
		sendCmd("summaryInfo[]");
		sendCmd("perBaseSeqQuality[]");
		sendCmd("perBaseSeqProbability[]");
		sendCmd("perBaseComposition[]");
		sendCmd("perBaseGCCont[]");
		sendCmd("perBaseNCont[]");
		sendCmd("readScoreDistro[]");
		sendCmd("seqGCDistro[]");
	}

	ws.onmessage = function(msg){
		var raw = JSON.parse(deserialize(msg.data));
		var msgType = raw[0];
		var msgData = raw[1];
		var msgOpts = raw[2];
		switch(msgType){
			case "summaryInfo":
				addSummaryInfo(msgData);
				break;
			case "meanPhredBySeq":
				drawLine(msgData,"bpSeqQuality", msgOpts, "item_0");
				break;
			case "meanProbBySeq":
				drawLine(msgData,"bpSeqProbability", msgOpts, "item_1");
				break;
			case "compositionByPosition":
				drawLine(msgData,"positionComposition", msgOpts, "item_2");
				break;
			case "perBaseGCCont":
				drawLine(msgData,"perBaseGCCont", msgOpts, "item_3");
				break;
			case "perBaseNCont":
				drawLine(msgData,"perBaseNCont", msgOpts, "item_4");
				break;
			case "readScoreDistro":
				drawLine(msgData,"readScoreDistro", msgOpts, "item_5");
				break;
			case "seqGCDistro":
				drawLine(msgData,"seqGCDistro", msgOpts, "item_6");
				break;
			case "Error":
				alert(msgData);
				break;
			default:
				console.log("No handler for message type: ",msgType);
		}
	}
}

function addSummaryInfo(data){
	var elems = $(".summaryData");
	for(i=0;i<elems.length;i++){
		$(elems[i]).html(data[i]);
	};
	$("#summaryTable").show();
}

function drawLine(data, div, opts, item){
	document.getElementById(item).className = "list-item fa fa-plus-circle";
	var thisChart = document.getElementById(div);
	var chartCont = thisChart.parentElement;
	opts.height = 300;
	opts.width = chartWidth;
	Plotly.newPlot(div, data, opts);
}





