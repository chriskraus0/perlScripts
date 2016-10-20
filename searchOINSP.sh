#!/bin/bash
FILE=""
FILE="$1"

while read Gene; do
TransGene=$(/home/christopher/programmes/perlScripts/transformHeaders.pl --headerTsv='omclGeneHeadersIndex.tsv' --query=$Gene)

java -jar OrthoInspector_comline_client.jar -mode single -organism_list all -query $TransGene -outfmt 3 -out $Gene.Oinsp.tsv 2>$Gene.Oinsp.err

/home/christopher/programmes/perlScripts/oinspOut3ToCounts.pl --oinsp3Tsv=$Gene.Oinsp.tsv --outputTsv=$Gene.Oinsp.counts.tsv --geneName=$Gene
done < $FILE
