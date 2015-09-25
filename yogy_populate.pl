#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;
use DBI;
use CGI;


# Open Files ###################################################################

my $dbh = connect_to_DB('mysql','S_pombe_YOGY_4','localhost','3306','','yogyrw','yogyex');


# global variables - hmmm!

my $count = 0;
my @temp;
my %species_hash ;
my @tmp;
my $type;
my $kogid;
my $string;
my @tmp2;
my $sp;
my $comp;
my $chromosome;
my $start;
my $end;
my $pombeid;


################################################################################

# Pre-made file to load species info for KOGs.

open (INPUT, "< ./species_db.txt")
    or die "couldn't open file\n";

while (<INPUT>) {

    next
        if /^>>/;

    $count++;

    @temp = split /\t/;

    my $species_id = ($count*10);

    $temp[1] = lc($temp[1]);

    $species_hash{$temp[1]} = $species_id;

}

#print Dumper \%species_hash;

close (INPUT);


################################################################################

# ftp://ftp.ncbi.nih.gov/pub/COG/KOG/kyva=gb

# Set as a soft link in this directory to make the file name nicer!

open(GIINPUT, "< ./GI_numbers_db.txt")
    or die "couldn't open file => GI_numbers_db.txt \n";

my $gi;
my %gi_hash = ();

while (<GIINPUT>) {
    s/\r//;
    chomp;
    @temp = split /\s+/;
    $gi_hash{lc($temp[0])} = $temp[1];

}

close(GIINPUT);


# ftp://ftp.ncbi.nih.gov/pub/COG/KOG/kog

open(KOGINPUT, "< ./kog_db.txt")
    or die "couldn't open file => kog_db.txt\n";

while (<KOGINPUT>) {

    chomp;

    if ($_ =~ m/^\[/) {

        s/\[//;

        @tmp = split /\]/;

        $type = $tmp[0];

        @temp = split /(\d{4})/, $tmp[1];

        $kogid = $temp[0].$temp[1];

        $kogid =~ s/^\s+//;
        $type =~ s/^\s+//;
        $temp[2] =~ s/^\s+//;

        insert_kog_rows($type, $kogid, $temp[2]);

        my @array = split //, $tmp[0];

        foreach (@array) {
            insert_kog_function_rows($_, $kogid,);
        }

    }

    if ($_ =~ m/^\s+\w{3}/) {

        @tmp = split /:/;

        $tmp[1] =~ s/^\s+//;
        $tmp[0] =~ s/^\s+//;

        $sp = $species_hash{$tmp[0]};

        $tmp[1] =~ s/\s+//;

        $gi = $tmp[1];
        $gi =~ s/_[1-99]//;

        insert_member_rows($kogid, $sp, $tmp[1], $gi_hash{lc($gi)} );

    }

}

close(KOGINPUT);


###############################################################################

# ftp://ftp.ncbi.nih.gov/pub/COG/KOG/fun.txt

open(FUN, "< ./fun_db.txt")
    or die "couldn't open file => fun_db.txt\n";

my $process_type;

while (<FUN>) {
    s/\r//g;
    chomp;
    if (m/^\w+/) {
        $process_type = $_;
    }

    if (m/\[/) {

        s/\[//g;
        @temp = split /\]/;
        $temp[0] =~ s/^\s+//;
        $temp[1] =~ s/^\s+//;
        insert_function_rows($temp[0], $temp[1], $process_type);
        #print "[$temp[0], $temp[1], $process_type]\n";

    }

}

close(FUN);


################################################################################

# From the GeneSpring annotation file in S:\data\Fission\ yeast on the
#   windows machines - soft link to change the file name to remove the space.

open(GENESPRING, "< ./Fission_yeas_annotations_db.txt")
    or die "couldn't open file => Fission_yeas_annotations_db.txt\n";

my %genespring_hash = ();

while (<GENESPRING>) {
    # $temp[0] the Systematic Name
    # $temp[2] the PombePD Product Phenotype
    # $temp[7] the GeneDB ID

    @temp = split /\t/;

    if (defined ($temp[4])) {

        $genespring_hash{lc($temp[4])} =$temp[10].'@'.$temp[8] if $temp[4] ne '';

    }

}

#print Dumper %genespring_hash;

close(GENESPRING);


# ftp://ftp.sanger.ac.uk/pub/yeast/pombe/Mappings/gp2swiss.txt

open(SWISS, "< ./gp2swiss_db.txt")
    or die "couldn't open file => gp2swiss_db.txt\n";

my %swissprot_hash = ();

while (<SWISS>) {
    s/\r//g;
    chomp;
    @temp = split /\t/;
    @tmp = split /:/, $temp[1];
    $swissprot_hash{lc($temp[0])} = $tmp[1];

}

#print Dumper %swissprot_hash;

close(SWISS);


# ftp://ftp.sanger.ac.uk/pub/yeast/pombe/Protein_data/pompep

open(GENEDB, "< ./pompep_db.txt")
    or die "couldn't open file => pompep_db.txt\n";

undef my @synonym_array;
undef my @geneDB_array;
undef my @pombepd_array;

my $undef = 'undefined';

while (<GENEDB>) {

    chomp;

    if ($_ =~ m/^>/) {

        my $genedb = ();
        my $descrip = ();

        @geneDB_array = split /\|/;

        $geneDB_array[0] =~ s/^>//;
        $geneDB_array[3] =~ s/\s+$//;
        $geneDB_array[0] =~ s/\s+$//;

        if (defined($geneDB_array[1])) {

            if ($geneDB_array[1] ne '') {
                $genedb = $geneDB_array[1];
            } else {
                $genedb = $undef;
            }

        } else {

            $genedb = $undef;

        }

        if (defined($geneDB_array[3])) {

            if ($geneDB_array[3] ne '') {
                $descrip = $geneDB_array[3];
            } else {
                $descrip = $undef;
            }

        } else {

            $descrip = $undef;

        }

        #print "Gene---->[$geneDB_array[0]][$genedb][$descrip]\n";

        @synonym_array = split /,/, $geneDB_array[2] if $geneDB_array[2] ne '';

        push @synonym_array, $geneDB_array[1] if $geneDB_array[1] ne '';

        if ($geneDB_array[2] ne '') {

            foreach (@synonym_array) {

                $_ =~ s/^\s+//;
                $_ =~ s/\s+$//;

                insert_synonym_rows(lc($geneDB_array[0]), lc($_));

                #print "synonym------->[$geneDB_array[0]][$_]\n"

            }

        }

        my $genespring_string = $genespring_hash{lc($geneDB_array[0])};

        my $swiss_id = $swissprot_hash{lc($geneDB_array[0])};

        $swiss_id = 'undefined' if !defined($swiss_id);

        if (defined ($genespring_string)) {

            #print "[$geneDB_array[0]]\n";

            my @genespring_array = split /@/, $genespring_string;

            #print "[$genespring_array[0]][$genespring_array[1]]\n" ;

            insert_gene_rows(lc($geneDB_array[0]), lc($genedb), $descrip,lc($genespring_array[0]), $genespring_array[1], $swiss_id, $geneDB_array[5]);

        } else {

            insert_gene_rows(lc($geneDB_array[0]), lc($genedb), $descrip, $undef, $undef, $swiss_id, $geneDB_array[5])

        }

    }

}

close(GENEDB);


################################################################################

# ftp://genome-ftp.stanford.edu/pub/yeast/gene_registry/registry.genenames.tab

open(BUDDING, "< ./registry.genenames.tab")
    or die "Couldn't Open File => budding genes\n";

while (<BUDDING>) {

    chomp;

    @temp = split /\t/;

    insert_budding_rows(@temp);

}

close(BUDDING);


################################################################################

# File from Val of latest curated pombe and budding yeast orthologs.
# This one is from 23 Jan 2006.

open(ORTHOLOGS, "< ./yeast_ortho_db.txt")
    or die "Couldn't Open File => ortholog table\n";

while (<ORTHOLOGS>) {

    @temp = split /\s+/;

    @tmp = split /\|/, $temp[1];

    $pombeid = $temp[0];

    foreach (@tmp) {

        insert_val_rows(lc($pombeid),lc($_));

    }

}

close(ORTHOLOGS);


################################################################################

# ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data

open(HOMOLOGENE, "./homologene_db.data")
    or die "Couldn't Open File => homologene_db.data\n";

while (<HOMOLOGENE>) {

    chomp;

    @temp = undef;

    @temp = split /\t/;

    insert_homologene_rows($temp[0],lc($temp[1]),lc($temp[2]),$temp[3],$temp[4],$temp[5]);

}

disconnect_from_DB();


# Subroutines #################################################################

sub connect_to_DB {

    my ($driver, $instance, $host, $port, $cnf_file, $user, $password) = @_;

    my $dbh = DBI->connect("DBI:${driver}:database=${instance};host=${host};port=$port;mysql_read_default_file=${cnf_file}",$user,$password)
        or die "ERROR:$DBI::errstr\n";

    if (!defined $dbh) {
        die "Could not connect to database";
    }

    return $dbh;
}


sub disconnect_from_DB {

    $dbh->disconnect()
        or die "Can't disconnect: $DBI::errstr\n";

}


###############################################################################

sub insert_kog_rows {

    my $sth_insert_gi = undef;

    my ($typ, $idkog, $descrip) = @_;

    unless ($sth_insert_gi) {

        my $string = qq(INSERT INTO kogs
                        (process_key, kog_id, description)
                        VALUES (?,?,?) );

        $sth_insert_gi = $dbh->prepare($string);

    }

    $sth_insert_gi->execute($typ, $idkog, $descrip);

}


###############################################################################

sub insert_member_rows {

    my $sth_insert_gi = undef;

    my ($koid, $speciesid, $proteinid, $gi) = @_;

    unless ($sth_insert_gi) {

        my $string = qq(INSERT INTO kog_member
                        (kog_id, species_id, protein_id, gi_number)
                        VALUES (?, ?, ?,?) );

        $sth_insert_gi = $dbh->prepare($string);

    }

    $sth_insert_gi->execute($koid, $speciesid, $proteinid, $gi);

}


###############################################################################

sub insert_function_rows {

    my $sth_insert_gi = undef;

    my ($pid, $p, $pt) = @_;

    unless ($sth_insert_gi) {

        my $string = qq(INSERT INTO function
                        (process_key, process, process_type)
                        VALUES (?, ?, ?) );

        $sth_insert_gi = $dbh->prepare($string);

    }

    $sth_insert_gi->execute($pid, $p, $pt);

}


###############################################################################

sub insert_kog_function_rows {

    my $sth_insert_gi = undef;

    my ($p, $k) = @_;

    unless ($sth_insert_gi) {

        my $string = qq(INSERT INTO kog_function
                        (process_key, kog_id)
                        VALUES (?, ?) );

        $sth_insert_gi = $dbh->prepare($string);

    }

    $sth_insert_gi->execute($p, $k);

}


###############################################################################

sub insert_gene_rows {

    my $sth_insert_gi = undef;

    my ($sys, $db, $des, $springname, $springdescrip, $swiss_id, $chrom) = @_;

    #print "[$sys][$db][$des]\n";

    unless ($sth_insert_gi) {

        my $string = qq(INSERT INTO pombe_gene
                        (GeneDB_systematic_id, GeneDB_primary, GeneDB_descrip, PombePD_Systematic, PombePD_Product_Phenotype, uni_id, chromosome)
                        VALUES (?, ?, ?, ?, ?, ?, ?) );

        $sth_insert_gi = $dbh->prepare($string);

    }

    $sth_insert_gi->execute($sys, $db, $des, $springname, $springdescrip, $swiss_id, $chrom);

}


###############################################################################

sub insert_synonym_rows {

    my $sth_insert_gi = undef;

    my ($id, $syn) = @_;

    unless ($sth_insert_gi) {

        my $string = qq(INSERT INTO pombe_synonyms
                        (protein_id, synonym)
                        VALUES (?, ?) );

        $sth_insert_gi = $dbh->prepare($string);

    }

    $sth_insert_gi->execute($id, $syn);

}


###############################################################################

sub insert_budding_rows {

    my $sth_insert = undef;

    my ($sym, $alt, $desc, $prod, $pheno, $sys_name, $sgd_id) = @_;

#    print "[$sym] [$alt] [$desc] [$prod] [$pheno] [$sys_name] [$sgd_id]\n";

    unless ($sth_insert) {

        my $string = qq(INSERT INTO budding_gene
                        (SGD_symbol, SGD_alternate, SGD_descrip, SGD_product, SGD_pheno, SGD_sys_name, SGDID)
                        VALUES (?, ?, ?, ?, ?, ?, ?) );

        $sth_insert = $dbh->prepare($string);

    }

    $sth_insert->execute($sym, $alt, $desc, $prod, $pheno, $sys_name, $sgd_id);

}


###############################################################################

sub insert_val_rows {

    my $sth_insert = undef;

    my ($pombe, $yeast) = @_;

    #print "[$pombe] [$yeast]\n";

    unless ($sth_insert) {

        my $string = qq(INSERT INTO vals_orthologs
                        (pombe_id,yeast_id)
                        VALUES (?, ?) );

        $sth_insert = $dbh->prepare($string);

    }

    $sth_insert->execute($pombe, $yeast);

}


###############################################################################

sub insert_homologene_rows {

    my $sth_homologene = undef;

    my ($HID, $tax, $gene_id, $gene_symbol, $gi_number, $protein_accession) = @_;

    unless ($sth_homologene) {

        my $string = qq(INSERT INTO homologene
                        (HID, tax_id, gene_id, gene_symbol, gi_number, protein_accession)
                        VALUES (?, ?, ?, ?, ?, ?) );

        $sth_homologene = $dbh->prepare($string);

    }

    $sth_homologene->execute($HID, $tax, $gene_id, $gene_symbol, $gi_number, $protein_accession);

}
