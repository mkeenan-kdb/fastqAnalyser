# fastqAnalyser

Please checkout the gif at the bottom for the tool in action.

This tool allows for efficient analysis fastq files. This tool was created over a weekend as a proof of concept. It is basically a copy of the publicly available tool - fastqc https://www.bioinformatics.babraham.ac.uk/projects/fastqc/ 

#####Source file description;
  *Source files are .fastq files - these are raw sequence reads from DNA sequencers
  *A read is a defined molecule in terms of length and (reported) sequence - In the case of genome sequencing, sequencers take many reads (maybe 50 - 250 'letters' in length). These reads will over lap with other reads and so we can use the overlapping to determine the relative order of given reads. Therefore having many reads (i.e. more overlaps between reads - termed coverage or depth of coverage) is very important in the case of genome sequencing.
  *A crucial part of genome sequencing (and any analysis of genomic data) requires that we have confidence in the actual reported sequence. This tool is a first attempt at handling this in kdb+. For the proof of concept, I have copied the various metrics defined in the link at the top (the fastqc tool).
  
#####Technical Description
*Files
  *Each read in the fastqc file contains 4 records;
    1.The Read id and length of that particular read (as well as some other information like direction)
    2.The actual reported sequence
    3.Optional - not used in this tool
    4.The score of each base (more information here - http://www.drive5.com/usearch/manual/quality_score.html)
    
*kdb+
  1.The file to be analysed is supplied as a command line argument (as .gz compressed or .fastq uncompressed) (q qc.q -s 4 -file /path/to/myFile.fastq)
  2.The file contents are read info kdb+ as chunks;
    *If compressed, the file contents stream into a named pipe as the file decompresses. .Q.fps
    *If uncompressed, the file is read as chunks using .Q.fsn
  3.Each chunk is sliced and sent out to the 4 slave threads (if the chunk has a number of records not divisible by 4 - aka a partial read, we simply hold onto it and prepend it to the following chunk)
  4.In each slave, we map the ascii chars of each base score to their corresponding number - this is used to calculate the probabilities of each base
  5.Aggregations by each base and by each sequence are done and the data is sent back to the main thread where it updates a global view of the currently caculated metrics
  6.After kdb+ has finished parising the file, all of the webhooks are exposed and the user can connect. Upon connection the calculated tables are queried and the results are sent back to the browser for further analysis.
  
  

  
