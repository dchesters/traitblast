
#######################################################################
 # Seven Settings:

run_ID=femaleITD

 # Assign to this variable the command to invoke blastn on your system:
blastn_command=blastn-2.2.28+-64bit

 # Query, fasta format sequence file:
query_fasta=$run_ID.fas2.subject

 # References, fasta format sequences, IDs corresponding to trait file.
references_fasta=$run_ID.fas2.remainder

 # References table, traits
references_traits=$run_ID.trait_records

 # E-value during blast searches. 
eval=1e-8

 # Percent identity cutoff for Blast (stage 1) top hit. 
pident=92
#######################################################################


# query IDs into array
rm current_trait_all_queries
sed -n "s/^>//p" $run_ID.fas2 > current_trait_all_queries
readarray -t list_queries < current_trait_all_queries

# if you want to delete previous result file:
rm all_results

# new results file for current trait
echo $run_ID >> all_results


for i in ${!list_queries[*]}
do
 current_query=${list_queries[$i]}
 # current_query=0417-A2-02-NA
 echo current query is $current_query


  #####################################################
  # FOR CURRENT QUERY

echo $current_query >> all_results

 # Current Leave One Out, get a single sequence. A file with only that seq, and a file with all except that seq.
rm current_LOO $run_ID.fas2.subject $run_ID.fas2.remainder
echo $current_query > current_LOO
perl remove_fasta_entries.pl -fasta_in $run_ID.fas2 -rm_list current_LOO -fasta_out $run_ID.fas2.subject -regex 0 -retain -blastclust_list 0 > screenout
perl remove_fasta_entries.pl -fasta_in $run_ID.fas2 -rm_list current_LOO -fasta_out $run_ID.fas2.remainder -regex 0 -remove -blastclust_list 0 > screenout

 # From here is the main tool for functional assignment to a query DNA barcode

grep $current_query $run_ID.trait_records >> all_results

 # Blast single query against current trait references 
rm $run_ID.B1
$blastn_command -task blastn -query $query_fasta -subject $references_fasta -out $run_ID.B1 -word_size 10 -perc_identity $pident -dust no -strand both -evalue $eval -num_threads 1 -max_target_seqs 100000 -outfmt '6 sseqid pident'

 # Get top hit ID (filter percent identity score), write to file.
rm hit_ref.ID hit_ref.fas
head -n 1 $run_ID.B1 | sed -n "s/\s\S*//p" > hit_ref.ID
perl remove_fasta_entries.pl -fasta_in $run_ID.fas2 -rm_list hit_ref.ID -fasta_out hit_ref.fas -regex 0 -retain -blastclust_list 0 > screenout

 # Blast references for neibourhood of top hit. Percent identity threshold for neibourhood is distance from query to nearest neibour
Dnn=$(head -n 1 $run_ID.B1 | sed -n "s/\S*\s//p")
echo $Dnn >> all_results
rm $run_ID.B2
$blastn_command -task blastn -query hit_ref.fas -subject $references_fasta -out $run_ID.B2 -word_size 10 -perc_identity $Dnn -dust no -strand both -evalue $eval -num_threads 1 -max_target_seqs 100000 -outfmt '6 qseqid sseqid evalue pident length'

 # Perl script to get trait intersection of reference neibourhood.
 # Required input:
 # 	1) Neibourhood blast search results
 #	2) File of reference traits
rm trait_intersection_RESULTS
perl trait_intersection.pl $run_ID.trait_records $run_ID.B2 > trait_intersection_RESULTS

grep "RESULT" trait_intersection_RESULTS >> all_results
echo "QueryDelimiter" >> all_results


  # FOR CURRENT QUERY
  #####################################################
done



