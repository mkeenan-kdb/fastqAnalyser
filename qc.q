//GLOBALS
.web.PORT:"50889"
.fastq.PROJ:"/home/michael/q/projects/genetics"
.fastq.SCORES:"!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"!1+til 94
//TEMP VARS
.tmp.tempSeq:()
.tmp.chunkN:0
.tmp.wo:{.util.logm"Connection opened by handle ",string[x];}
.tmp.ws:{
 .util.logm"Adding delay to test spinners on front-end";
 system["sleep 0.2"];
 fn:".web.",.j.k -9!x;
 res:@[value;fn;(`Error;"Error in function:",fn)];
 neg[.z.w][-8!.j.j res];
 }
.tmp.wc:{.util.logm"Connection closed by handle ",string[x];}
//UTILS
.util.fmtNum:{reverse csv sv 3 cut reverse string[x]}
.util.logm:{-1("@"sv string(x;y))," - ",string[.z.T]," - ",z;}[.z.u;.z.h;]
.util.prob:{10 xexp neg[x]%10}
.util.meanParse:{(`$"mean_",string[x];(%;x;`numBases))}
.util.getMetric:{x i where c>i:y+4*til(c:count x)+1}
.util.writecsv:{.Q.dd[`:.;` sv x,`csv]0:csv 0:0!value x}
.util.mkfifo:{@[system;"rm -rf ",p:.fastq.PROJ,"/tmp";()]; @[system;"mkdir -p ",p;()]; @[system;"mkfifo ",p:p,"/genefifo";()];p}
.util.fixOffset:{
 raw:.tmp.tempSeq,x;
 .tmp.tempSeq:();
 extra:neg[(count raw)mod 16];
 .tmp.tempSeq:extra#raw;
 :extra _raw;
 }
//WEB HOOKS
.web.expose:{
 /expose the system to the outside world after the processing is complete
 system["p ",.web.PORT];
 `.z.wo`.z.ws`.z.wo set'(.tmp.wo;.tmp.ws;.tmp.wo);
 }
.web.summaryInfo:{
 fn:last "/"vs .fastq.FILE;
 nr:.util.fmtNum(first baseinfo)`numBases;
 lens:" - "sv .util.fmtNum each (select (min;max)@\:length from readinfo)`length;
 gc:string `int$100*exec avg gcCont from readinfo; 
 :(`summaryInfo;(fn;nr;lens;gc));
 }
/TODO functionalise the opts for charts - seperated here for dev
.web.perBaseSeqQuality:{
 data:enlist @[flip select x:position,y:phred from baseinfo;`mode`connectgaps`line;:;("lines";1b;`color`width!("rgb(255, 0, 0)";0.7))];
 opts:`title`showlegend`autosize`margin!("Per Base Sequence Quality";0b;0b;`l`r`t`b!40 40 40 40);
 :(`meanPhredBySeq;data;opts);
 }
.web.perBaseSeqProbability:{
 data:enlist @[flip select x:position,y:probs from baseinfo;`mode`connectgaps;:;("lines";1b)];
 opts:`title`showlegend`autosize`margin!("Probability Per Base";0b;0b;`l`r`b`t!40 40 40 40);
 :(`meanProbBySeq;data;opts);
 }
.web.perBaseComposition:{
 data:@[;`mode`connectgaps;:;("lines";1b)]@/:{flip ?[baseinfo;();0b;`x`y!`position,x]}each `mean_numA`mean_numT`mean_numG`mean_numC;
 opts:`title`showlegend`autosize`margin!("Per Base Composition";0b;0b;`l`r`t`b!40 40 40 40);
 :(`compositionByPosition;data;opts);
 }
.web.perBaseGCCont:{
 data:enlist @[flip select x:position,y:gcCont from baseinfo;`mode`connectgaps;:;("lines";1b)];
 opts:`title`showlegend`autosize`margin!("Per Base GC content";0b;0b;`l`r`t`b!40 40 40 40);
 :(`perBaseGCCont;data;opts);
 }
.web.perBaseNCont:{
 data:enlist @[flip select x:position,y:mean_numN from baseinfo;`mode`connectgaps;:;("lines";1b)];
 opts:`title`showlegend`autosize`margin!("Per Base N content";0b;0b;`l`r`t`b!40 40 40 40);
 :(`perBaseNCont;data;opts);
 }
.web.readScoreDistro:{
 data:enlist @[flip 0!`x xasc select y:count i by x:`int$meanPhred from readinfo;`mode`connectgaps;:;("lines";1b)];
 opts:`title`showlegend`autosize`margin!("Read score distribution";0b;0b;`l`r`t`b!40 40 40 40);
 :(`readScoreDistro;data;opts);
 }
.web.seqGCDistro:{
 data:enlist @[flip 0!`x xasc select y:count i by x:`int$100*gcCont from readinfo;`mode`connectgaps;:;("lines";1b)];
 opts:`title`showlegend`autosize`margin!("GC distribution";0b;0b;`l`r`t`b!40 40 40 40);
 :(`seqGCDistro;data;opts);
 }
//MAIN
.fastq.buildBaseTable:{[raw]
 /init
 readID:`$(first each" "vs'.util.getMetric[raw;0])inter\:".",.Q.an except"_";
 seqs:.util.getMetric[raw;1];
 scores:.fastq.SCORES@/:.util.getMetric[raw;3];
 probs:.util.prob each scores;
 lens:count each seqs;
 numATGCN:sum@/:'"ATGCN"=\:/:seqs;
 /read info
 reads:`read`length`gcCont`meanPhred`meanProb!(readID;lens;(sum each numATGCN[;2 3])%(lens);avg@/:scores;avg@/:probs); 
 reads:flip reads,`numA`numT`numG`numC`numN!flip numATGCN;
 /position info
 bases:`numA`numT`numG`numC`numN`numBases!flip{{(sum each "ATGCN"=\:x),count x}x[;y]}[seqs;]each til max lens;
 bases:flip bases,`phred`probs!flip{[s;p;i]{sum y[;x]}[i;]each (s;p)}[scores;probs;]each til max lens;
 bases:`position xkey update position:i from bases;
 :(reads;bases); 
 }
.fastq.parseChunk:{[raw]
 /init
 .tmp.chunkN+:1;
 if[0=.tmp.chunkN mod 10;2".";];
 raw:.util.fixOffset[raw];
 tabs:.Q.fc .(.fastq.buildBaseTable;raw);
 tabs:tabs(0 1)+\:2*til(count tabs)div 2;
 `readinfo upsert raze tabs[0];
 if[1=.tmp.chunkN;`baseinfo set pj/[tabs[1]];:();];
 `baseinfo set update position:i from baseinfo,(exec max length from readinfo)#0#baseinfo;
 `baseinfo set (pj/[tabs[1]]) pj baseinfo;
 }

.fastq.run:{
 opts:.Q.opt .z.x;
 err:"Must pass -file /path/to/file.fastq Exiting.";
 $[not`file in key opts;
   [.util.logm err;exit 1];
   all null .fastq.FILE:first opts`file;
   [.util.logm err;exit 2];()];
 .util.logm"Streaming ",.fastq.FILE," in chunks";
 st:.z.T;
 $["gz"~-2#.fastq.FILE;
   [fifo:.util.mkfifo[];system"pigz -dc ",.fastq.FILE," > ",fifo," &";.Q.fps[{.fastq.parseChunk[x]}]hsym`$fifo];
   .Q.fsn[{.fastq.parseChunk[x]};hsym`$.fastq.FILE;320000]];
 ![`baseinfo;();0b;((!). flip .util.meanParse each `numA`numT`numG`numC`numN),k!{(%;x;`numBases)}each k:`phred`probs];
 update gcCont:(numG+numC)%numBases from `baseinfo;
 -1"\n";.util.logm"Done. Time taken :",string .z.T-st;
 .web.expose[];
 .util.logm"View results at: http://",string[.z.h],":",.web.PORT,"/index.html";
 }

.fastq.run[]
