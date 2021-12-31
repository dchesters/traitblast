
# 
# 
# 
# 
# 
# to run:
# perl trait_intersection.pl [trait_records] [Neibourhood_blast_results]
# e.g.:
# perl trait_intersection.pl trait_records.femaleITD femaleITD.B2
# 
# 
# 
# Trait records file should be tab delimited, 
#	and have at minimum columns with sequence_ID and assigned_state, something like:
# trait         seqID   value   state
# femaleITD	402137	1.3244	B
# femaleITD	402138	1.3278	B
#
# 
# 
# 
# 
# 
#################################################################################################################


$trait_records 		= $ARGV[0];
$neibourhood_blast 	= $ARGV[1];

# In the trait table I have sequence ID in column 2 (Perl array index 1) and trait state in column 4 (index 3).
# if you have different then change these accordingly:
$sequence_ID_column 	= 1;
$state_column 		= 3;


#################################################################################################################


open(IN1, $trait_records) || die "\nERROR, cant open input:$trait_records\n";
print "reading trait_records file:$trait_records\n";
while(my $line = <IN1>)
	{

#	print "$line";
# trait         seqID   value   state
# femaleITD	402137	1.3244	B
# femaleITD	402138	1.3278	B

	$line =~ s/\n//;$line =~ s/\r//;
	my @split_line = split /\t/, $line;
	my $seqID = $split_line[$sequence_ID_column];
	my $state = $split_line[$state_column];

	if($seqID =~ /[\d\w]/ && $state =~ /[\d\w]/)
		{
		$states{$seqID} = $state;$lines_parsed++;
		};
	};
close IN1;
print "parsed $lines_parsed lines.
";

#################################################################################################################

open(IN2, $neibourhood_blast) || die "\nERROR, cant open input:$neibourhood_blast\n";
print "reading neibourhood_blast file:$neibourhood_blast\n";

my $states_returned_for_hits = 0;
my %states_count = ();

while(my $line = <IN2>)
	{

#	print "$line";
#[qseqid sseqid evalue pident length sstart send qframe sframe]
#400687	400687	0.0	100.00	549	1	549	1	1
#400687	401048	0.0	100.00	549	1	549	1	1

	$line =~ s/\n//;$line =~ s/\r//;
	my @split_line = split /\t/, $line;
	my $qseqid = $split_line[0];
	my $sseqid = $split_line[1];
	my $evalue = $split_line[2];
	my $pident = $split_line[3];

	# nb subject used in blast search includes query (stage 1 top hit), and will probably be first row. so can ignore qseqid.

	if($states{$sseqid} =~ /./)
		{
		$hit_state = $states{$sseqid};$states_returned_for_hits++;
		if($all_hit_states =~ /$hit_state/){}else{$all_hit_states .= "$hit_state"};
		$states_count{$hit_state}++;
		}else{
		$states_not_returned_for_hits++;
		};

	};
close IN2;


#################################################################################################################

if($states_returned_for_hits == 0 )
	{
	print "\nfailed to retreive states for query.\n"
	}else{

@states_counts = keys %states_count;
my $predominent_state;
if(scalar @states_counts == 1)
	{
	$predominent_state = $all_hit_states
	}else{

	my $max_count = 0;my $max_state;
	foreach my $s(@states_counts)	
		{
		$current_count = $states_count{$s};
		if($current_count >= $max_count){$max_count = $current_count; $max_state = $s};
		};
	$predominent_state = $max_state;

	};

print "
states_returned_for_hits:$states_returned_for_hits
states_NOT_returned_for_hits:$states_not_returned_for_hits

RESULT1, state(s) assigned to query:$all_hit_states
RESULT2, predominent_state:$predominent_state
";

	};








