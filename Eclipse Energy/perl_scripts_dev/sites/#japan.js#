function start(){
	parent.menu_edit();
}

function menu_edit() {
	var W_TABLEID = ""
	W_TABLEID = parent.id_get();
	parent.rightframe_edit(W_TABLEID);
}

function id_get(){
	var W_TABLEID	= "";
	if (parent.location.search != ""){
		var M_IDX		= top.location.href.indexOf("M");
		var AMP_IDX		= top.location.href.indexOf("&",M_IDX);
		W_TABLEID	    = top.location.href.substring(M_IDX + 2,AMP_IDX);
	}
	return W_TABLEID;
}


function rightframe_edit(P_TABLEID){
	var W_URL = "";
	switch (P_TABLEID){
		case "01"	:	W_URL = "jccht01e.htm?";	break;
		case "03"	:	W_URL = "jccht03e.htm?";	break;
		case "05"	:	W_URL = "jccht05e.htm?";	break;
		case "07"	:	W_URL = "jccht07e.htm?";	break;
		case "09"	:	W_URL = "jccht09e.htm?";	break;
		case "11"	:	W_URL = "jccht11e.htm?";	break;
		case "13"	:	W_URL = "jccht13e.htm?";	break;
		case "15"	:	W_URL = "jccht15e.htm?";	break;
		case "17"	:	W_URL = "jccht17e.htm?";	break;
		case "19"	:	W_URL = "jccht19e.htm?";	break;
		case "21"	:	W_URL = "jccht21e.htm?";	break;
		case "23"	:	W_URL = "jccht23e.htm?";	break;
		case "25"	:	W_URL = "jccht25e.htm?";	break;
		case "27"	:	W_URL = "jccht27e.htm?";	break;
		case "29"	:	W_URL = "jccht29e.htm?";	break;
		case "31"	:	W_URL = "jccht31e.htm?";	break;
		case "33"	:	W_URL = "jccht33e.htm?";	break;
		case "35"	:	W_URL = "jccht35e.htm?";	break;
		case "37"	:	W_URL = "jccht37e.htm?";	break;
		case "39"	:	W_URL = "jccht39e.htm?";	break;
		case "41"	:	W_URL = "jccht41e.htm?";	break;
		case "43"	:	W_URL = "jccht43e.htm?";	break;
		case "45"	:	W_URL = "jccht45e.htm?";	break;
		case "47"	:	W_URL = "jccht47e.htm?";	break;
		case "49"	:	W_URL = "jccht49e.htm?";	break;
		case "51"	:	W_URL = "jccht51e.htm?";	break;
		case "53"	:	W_URL = "jccht53e.htm?";	break;
		case "55"	:	W_URL = "jccht55e.htm?";	break;
		case "57"	:	W_URL = "jccht57e.htm?";	break;
		case "59"	:	W_URL = "jccht59e.htm?";	break;
		case "61"	:	W_URL = "jccht61e.htm?";	break;
		case "63"	:	W_URL = "jccht63e.htm?";	break;
		case "65"	:	W_URL = "jccht65e.htm?";	break;
		case "67"	:	W_URL = "jccht67e.htm?";	break;
		case "69"	:	W_URL = "jccht69e.htm?";	break;
		case "71"	:	W_URL = "jccht71e.htm?";	break;
		case "73"	:	W_URL = "jccht73e.htm?";	break;
		case "75"	:	W_URL = "jccht75e.htm?";	break;
		case "77"	:	W_URL = "jccht77e.htm?";	break;
		case "79"	:	W_URL = "jccht79e.htm?";	break;

		default		:	W_URL = "tope.htm";	
	}
	var P_IDX   = top.location.search.indexOf("P",0);
	var COM_IDX = top.location.search.indexOf(",",P_IDX + 1);

	if(COM_IDX > 0) {
		W_URL = W_URL + "&" + top.location.search.substring(P_IDX);
	}

	if(P_TABLEID != ""){
		var INT_P_TABLEID = parseInt(P_TABLEID,10);
		if (INT_P_TABLEID >= 0 && INT_P_TABLEID <= 79) {
			if (INT_P_TABLEID % 2==1) {
				parent.FR_M_INFO.location.href = W_URL;
			}	
		}	
	}
}
function top_load(){
	parent.FR_M_INFO.document.open();
	if((top.location.search.indexOf("M=&P=") < 0) && (top.location.search != "")){
		parent.menu_edit();
	}
}

function top_write(PARAM_STR){
	parent.FR_M_INFO.document.writeln(PARAM_STR);
}