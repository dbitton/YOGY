#!/bin/sh
# Commands to make the MySQL tables.

# Only need to drop if the database is not new!

echo "Creating empty database"

mysql -h localhost -P 3306 -u yogyrw -pyogyex S_pombe_YOGY_4 < create_yogy.sql

# In the following scripts, it is necessary to download certain
#   database files from the internet - the locations of these
#   files are given in the relevant script or in this script.


# Files to download in perl script.

echo "Initial population of data"

./yogy_populate.pl


# Selected files to download from:
#   http://inparanoid.cgb.ki.se/download/current/sqltables/

echo "Adding Inparanoid"
#cd /home/sk11/load2/inptables/inparanoid.sbc.su.se/download/7.0_current/sqltables
for file in $(cat ../inparanoid_files.txt)
do
  echo $file

 ./yogy_add_inp_terms.pl ../inptables/inparanoid.sbc.su.se/download/7.0_current/sqltables/$file

done


# http://orthomcl.cbil.upenn.edu/ORTHOMCL_DB/all_orthomcl.out

echo "Adding OrthoMCL clusters"

./yogy_add_orthomcl_cluster.pl all_orthomcl.out

# http://orthomcl.cbil.upenn.edu/ORTHOMCL_DB/BAE_geneid_anno

echo "Adding OrthoMCL lookup names"

./yogy_add_orthomcl_lookup.pl BAE_geneid_anno


# File to download in perl script.

echo "Adding GO terms"

./yogy_add_go_terms.pl

# Selected files to download from:
#   http://www.geneontology.org/GO.current.annotations.shtml

echo "Adding GO associations"

for file in $(cat go_files.txt)
do
  echo $file

  gunzip $file

  ./yogy_add_go_assocs.pl $file

 # gzip $file:r
#commented by sanjay rec
done

# Same location, renamed file, so that it doesn't get loaded
#   with the previous loop!

set file = "gene_association.goa_uniprot_noiea.gz"

gunzip $file

echo "Adding GO associations for UniProt"

./yogy_add_go_assocs_uni.pl $file

gzip $file

#######did everything until this point 16/02/12
# Files to download in perl script.
# This script may fail during running, so some of it may need to be re-run.

echo "Adding non yeast organisms"

gunzip functional_descriptions.WS190.txt.gz
gunzip SwissProt_mappings.WS190.txt.gz

./yogy_add_new_orgs.pl

gzip functional_descriptions.WS190.txt
gzip SwissProt_mappings.WS190.txt




# Selected xrefs files to download from:
#   ftp://ftp.ebi.ac.uk/pub/databases/IPI/current/

echo "Adding IPI lookup info"
for file in $(cat ipi_files.txt)
do
  echo $file

  #gunzip $file

  ./yogy_add_ipi_lookup.pl $file

  #gzip $file:r

done



# ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2accession.gz

set file = "gene2accession.gz"

gunzip $file

echo "Adding GI lookup info"

./yogy_add_gi_lookup.pl $file

gzip $file

#commented by sanjay rec
# CURRENT LOCATION

# ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz

cd uni_parse

set file = "uniprot_sprot"

gunzip ${file}.dat.gz

echo "Parsing SwissProt"

./uni_parse.pl ${file}.dat > ${file}.txt

gzip ${file}.dat

echo "Adding SwissProt lookup info"

../yogy_add_uniprot_lookup.pl ${file}.txt

gzip ${file}.txt

cd ..
# ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.dat.gz

cd uni_parse

set file = "uniprot_trembl"

gunzip ${file}.dat.gz

echo "Parsing TrEMBL"

./uni_parse.pl ${file}.dat > ${file}.txt

gzip ${file}.dat

echo "Adding TrEMBL lookup info"

../yogy_add_uniprot_lookup.pl ${file}.txt

gzip ${file}.txt
#commented by Sanjay rec

cd ..

# Instructions on how to download file given in perl script.

./yogy_add_eco.pl

# Takes a couple of days to run this script!
# It speeeds up the on-the-fly searching for UniProt IDs from GI numbers.

echo "Pre-calculating UniProt IDs to GI conversions"

./yogy_find_uniprot_ids.pl

