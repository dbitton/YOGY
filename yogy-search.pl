#!/usr/local/bin/perl -wT 

#
# Author: jam
# Maintainer: cjp
# Created:
# Last Modified: 2006-03-29 cjp: tidying
#

use strict;

use lib qw(/var/www/lib/core);
use SangerWeb;

use CGI qw/:cgi :standard/;
use CGI::Carp qw(fatalsToBrowser);

#use Data::Dumper;

use DBI;

use GD;
use GD::Graph::bars;
use GD::Graph::colour qw(:colours);

use Website::Utilities::IdGenerator;

$ENV{PATH} = '';


# TODO: less global variables!

use vars qw($TMPURI $TMPDIR $all_go_ids
            $gi_query $ens_query $uni_query
            $gBlank $gStyle $gNone
            @go_search_species @kogs_species_id @search_gos
            %species_id %species_name %species_tax
            %species_tax_rev %species_tax_rev2
            %species_1let %species_2let
            %species_3let %species_3let_rev
            %species_colour %ensembl_species
            %inparanoid_species %inparanoid_org_names
            %species_hrefs %species_href_titles
            %function_colour %go_aspect_colour
            %go_aspect_href  %go_aspect_title
            %go_evid_colour %go_evid_title);

$TMPURI = '/tmp/spge';
$TMPDIR = $ENV{DOCUMENT_ROOT} . $TMPURI;

$gi_query  = '';
$ens_query = '';
$uni_query = '';

undef $all_go_ids;

$gBlank = '_blank';
$gStyle = 'font-family: Verdana; text-decoration: none';
$gNone  = 'text-decoration: none';

@go_search_species = qw(10 20 30 40 50 60 130 150 160 170 180 250);

@kogs_species_id = qw(10 20 30 40 50 60 70);

undef @search_gos;

# TODO: many of these hashes should really be put into a database!

%species_id = ('A._thaliana'     => '10',
               'C._elegans'      => '20',
               'D._melanogaster' => '30',
               'H._sapiens'      => '40',
               'S._cerevisiae'   => '50',
               'S._pombe'        => '60',
               'M._musculus'     => '130',
               'R._norvegicus'   => '150',
               'P._falciparum'   => '170',
               'E._coli'         => '180',
               'D._discoideum'   => '250');

%species_name = (10  => 'Arabidopsis thaliana',
                 20  => 'Caenorhabditis elegans',
                 30  => 'Drosophila melanogaster',
                 40  => 'Homo sapiens',
                 50  => 'Saccharomyces cerevisiae',
                 60  => 'Schizosaccharomyces pombe',
                 70  => 'Encephalitozoon cuniculi',
                 80  => 'Anopheles gambiae',
                 90  => 'Caenorhabditis briggsae',
                 100 => 'Danio rerio',
                 110 => 'Takifugu rubripes',
                 120 => 'Gallus gallus',
                 130 => 'Mus musculus',
                 140 => 'Pan troglodytes',
                 150 => 'Rattus norvegicus',
                 160 => 'Oryza sativa',
                 170 => 'Plasmodium falciparum',
                 180 => 'Escherichia coli',
                 190 => 'Magnaporthe grisea',
                 200 => 'Neurospora crassa',
                 210 => 'Eremothecium gossypii',
                 220 => 'Apis mellifera',
                 230 => 'Canis familiaris',
                 240 => 'Tetraodon nigroviridis',
                 250 => 'Dictyostelium discoideum',
                 260 => 'Drosophila pseudoobscura',
                 270 => 'Kluyveromyces lactis',
                 280 => 'Cryptococcus neoformans',
                 290 => 'Yarrowia lipolytica',
                 300 => 'Debaryomyces hansenii',
                 310 => 'Ashbya gossypii',
                 320 => 'Candida glabrata');

%species_tax = (3702   => '10',
                6239   => '20',
                7227   => '30',
                9606   => '40',
                4932   => '50',
                4896   => '60',
                6035   => '70',
                7165   => '80',
                6238   => '90',
                7955   => '100',
                31033  => '110',
                9031   => '120',
                10090  => '130',
                9598   => '140',
                10116  => '150',
                4530   => '160',
                5833   => '170',
                562    => '180',
                148305 => '190',
                5141   => '200',
                33169  => '210',
                7460   => '220',
                9615   => '230',
                99883  => '240',
                44689  => '250',
                7237   => '260',
                28985  => '270',
                214684 => '280', # ???
                284591 => '290',
                284592 => '300',
                284811 => '310', # ???
                284593 => '320');

%species_tax_rev = (10  => '3702',
                    20  => '6239',
                    30  => '7227',
                    40  => '9606',
                    50  => '4932',
                    60  => '4896',
                    70  => '6035',
                    80  => '7165',
                    90  => '6238',
                    100 => '7955',
                    110 => '31033',
                    120 => '9031',
                    130 => '10090',
                    140 => '9598',
                    150 => '10116',
                    160 => '4530',
                    170 => '5833',
                    180 => '562',
                    190 => '148305',
                    200 => '5141',
                    210 => '33169',
                    220 => '7460',
                    230 => '9615',
                    240 => '99883',
                    250 => '44689',
                    260 => '7237',
                    270 => '28985',
                    280 => '214684',
                    290 => '284591',
                    300 => '284592',
                    310 => '284811',
                    320 => '284593');

%species_tax_rev2 = (10  => '3702',
                     20  => '6239',
                     30  => '7227',
                     40  => '9606',
                     50  => '4932',
                     60  => '284812',
                     70  => '284813',
                     80  => '180454',
                     90  => '6238',
                     100 => '7955',
                     110 => '31033',
                     120 => '208526',
                     130 => '10090',
                     140 => '9598',
                     150 => '10116',
                     160 => '39947',
                     170 => '36329',
                     180 => '562',
                     190 => '242507',
                     200 => '5141',
                     210 => '33169',
                     220 => '7460',
                     230 => '9615',
                     240 => '99883',
                     250 => '44689',
                     260 => '7237',
                     270 => '284590',
                     280 => '214684',
                     290 => '284591',
                     300 => '284592',
                     310 => '284811',
                     320 => '284593');

%species_1let = (10  => 'A',
                 20  => 'C',
                 30  => 'D',
                 40  => 'H',
                 50  => 'Y',
                 60  => 'P',
                 70  => 'E');

%species_2let = (10  => 'AT',
                 20  => 'CE',
                 30  => 'DM',
                 40  => 'HS',
                 50  => 'SC',
                 60  => 'SP',
                 70  => 'EnC',
                 80  => 'AG',
                 90  => 'CB',
                 100 => 'DR',
                 110 => 'FR',
                 120 => 'GG',
                 130 => 'MM',
                 140 => 'PT',
                 150 => 'RN',
                 160 => 'OS',
                 170 => 'PF',
                 180 => 'EC',
                 190 => 'MG',
                 200 => 'NC',
                 210 => 'EG',
                 220 => 'AP',
                 230 => 'CF',
                 240 => 'TN',
                 250 => 'DD',
                 260 => 'DP',
                 270 => 'KL',
                 280 => 'CN',
                 290 => 'YL',
                 300 => 'DH',
                 310 => 'AsG',
                 320 => 'CG');

%species_3let = (10  => 'Ath',
                 20  => 'Cel',
                 30  => 'Dme',
                 40  => 'Hsa',
                 50  => 'Sce',
                 60  => 'Spo',
                 70  => 'Ecu',
                 80  => 'Aga',
                 90  => 'Cbr',
                 100 => 'Dre',
                 110 => 'Fru',
                 120 => 'Gga',
                 130 => 'Mmu',
                 140 => 'Ptr',
                 150 => 'Rno',
                 160 => 'Osa',
                 170 => 'Pfa',
                 180 => 'Eco',
                 190 => 'Mgr',
                 200 => 'Ncr',
                 210 => 'Ego',
                 220 => 'Ame',
                 230 => 'Cfa',
                 240 => 'Tni',
                 250 => 'Ddi',
                 260 => 'Dps',
                 270 => 'Kla',
                 280 => 'Cne',
                 290 => 'Yli',
                 300 => 'Dha',
                 310 => 'Ago',
                 320 => 'Cgl');

%species_3let_rev = (Ath => '10',
                     Cel => '20',
                     Dme => '30',
                     Hsa => '40',
                     Sce => '50',
                     Spo => '60',
                     Ecu => '70',
                     Aga => '80',
                     Cbr => '90',
                     Dre => '100',
                     Fru => '110',
                     Gga => '120',
                     Mmu => '130',
                     Ptr => '140',
                     Rno => '150',
                     Osa => '160',
                     Pfa => '170',
                     Eco => '180',
                     Mgr => '190',
                     Ncr => '200',
                     Ego => '210',
                     Ame => '220',
                     Cfa => '230',
                     Tni => '240',
                     Ddi => '250',
                     Dps => '260',
                     Kla => '270',
                     Cne => '280',
                     Yli => '290',
                     Dha => '300',
                     Ago => '310',
                     Cgl => '320');

%species_colour = (10  => '#ccffcc',
                   20  => '#ffffcc',
                   30  => '#ffddcc',
                   40  => '#ffccff',
                   50  => '#ccddff',
                   60  => '#ccccff',
                   70  => '#cceecc',
                   80  => '#ffdfdf',
                   90  => '#ffffe3',
                   100 => '#bbebff',
                   110 => '#8ceffd',
                   120 => '#ffdfff',
                   130 => '#efe7cf',
                   140 => '#eedcc8',
                   150 => '#f0dcd5',
                   160 => '#d1ffb3',
                   170 => '#c9decb',
                   180 => '#eeeea2',
                   190 => '#ffe920',
                   200 => '#ffdd75',
                   210 => '#ffc848',
                   220 => '#ffffe3',
                   230 => '#efdcaa',
                   240 => '#a1def4',
                   250 => '#d2dbd5',
                   260 => '#ffe6dd',
                   270 => '#cceeff',
                   280 => '#ffccaa',
                   290 => '#ffd7aa',
                   300 => '#ffc7aa',
                   310 => '#ccd7ff',
                   320 => '#cce7ff');

%ensembl_species = (20  => 'Caenorhabditis_elegans',
                    30  => 'Drosophila_melanogaster',
                    40  => 'Homo_sapiens',
                    80  => 'Anopheles_gambiae',
                    90  => 'Caenorhabditis_briggsae',
                    100 => 'Danio_rerio',
                    110 => 'Fugu_rubripes',
                    120 => 'Gallus_gallus',
                    130 => 'Mus_musculus',
                    140 => 'Pan_troglodytes',
                    150 => 'Rattus_norvegicus',
                    230 => 'Canis_familiaris');

%inparanoid_species = (ncbAT => '10',
                       ensCE => '20',
                       modCE => '20',
                       ensDM => '30',
                       modDM => '30',
                       ensHS => '40',
                       modSC => '50',
                       modSP => '60',
                       ensAG => '80',
                       modCB => '90',
                       ensDR => '100',
                       ensFR => '110',
                       ensGG => '120',
                       ensMM => '130',
                       modMM => '130',
                       ensPT => '140',
                       ensRN => '150',
                       modRR => '150',
                       modOG => '160',
                       sanPF => '170',
                       ncbEC => '180',
                       ensAM => '220',
                       ensCF => '230',
                       ensTN => '240',
                       modDD => '250',
                       modDP => '260');

%inparanoid_org_names = (ensAG => 'A. gambiae (Ensembl)',
                         ensAM => 'A. mellifera (Ensembl)',
                         ensCE => 'C. elegans (Ensembl)',
                         ensCF => 'C. familiaris (Ensembl)',
                         ensDM => 'D. melanogaster (Ensembl)',
                         ensDR => 'D. rerio (Ensembl)',
                         ensFR => 'F. rubripes (Ensembl)',
                         ensGG => 'G. gallus (Ensembl)',
                         ensHS => 'H. sapiens (Ensembl)',
                         ensMM => 'M. musculus (Ensembl)',
                         ensPT => 'P. troglodytes (Ensembl)',
                         ensRN => 'R. norvegicus (Ensembl)',
                         ensTN => 'T. nigroviridis (Ensembl)',
                         modCB => 'C. briggsae (Model)',
                         modCE => 'C. elegans (Model)',
                         modDD => 'D. discoideum (Model)',
                         modDM => 'D. melanogaster (Model)',
                         modDP => 'D. pseudoobscura (Model)',
                         modMM => 'M. musculus (Model)',
                         modOG => 'O. sativa (Model)',
                         modRR => 'R. norvegicus (Model)',
                         modSC => 'S. cerevisiae (Model)',
                         modSP => 'S. pombe (Model)',
                         ncbAT => 'A. thaliana (NCBI)',
                         ncbEC => 'E. coli (NCBI)',
                         sanPF => 'P. falciparum (Sanger)');

%species_hrefs = (Ath => 'http://www.arabidopsis.org/servlets/Search?type=general&search_action=detail&method=1&sub_type=gene&name=',
                  Cel => 'http://www.wormbase.org/db/gene/gene?name=',
                  Ddi => 'http://dictybase.org/db/cgi-bin/gene_page.pl?dictybaseid=',
                  Dme => 'http://flybase.net/cgi-bin/fbidq.html?',
                  Eco => 'http://http://ecogene.org/geneinfo.php?eg_id=',
                  Mmu => 'http://www.informatics.jax.org/searches/accession_report.cgi?id=',
                  Pfa => 'http://old.genedb.org/genedb/Search?organism=malaria&name=',
                  Rno => 'http://rgd.mcw.edu/tools/genes/genes_view.cgi?id=',
                  Sce => 'http://db.yeastgenome.org/cgi-bin/locus.pl?locus=',
                  Spo => 'http://www.old.genedb.org/genedb/Search?organism=S.+pombe&name=');

%species_href_titles = (Ath => 'TAIR',
                        Cel => 'WormBase',
                        Ddi => 'dictyBase',
                        Dme => 'FlyBase',
                        Eco => 'EcoGene',
                        Mmu => 'MGI',
                        Pfa => 'GeneDB',
                        Rno => 'RGD',
                        Sce => 'SGD',
                        Spo => 'GeneDB');

%function_colour = (A => '#fcdcfc',
                    B => '#fcdccc',
                    C => '#bcfcfc',
                    D => '#fcfcdc',
                    E => '#dcfcfc',
                    F => '#dcecfc',
                    G => '#ccfcfc',
                    H => '#dcdcfc',
                    I => '#dcccfc',
                    J => '#fcccfc',
                    K => '#fcdcec',
                    L => '#fcdcdc',
                    M => '#ecfcac',
                    N => '#dcfcac',
                    O => '#9cfcac',
                    P => '#ccccfc',
                    Q => '#bcccfc',
                    R => '#e0e0e0',
                    S => '#cccccc',
                    T => '#fcfcac',
                    U => '#acfcac',
                    V => '#fcfcbc',
                    W => '#bcfcac',
                    Y => '#fcfccc',
                    Z => '#ccfcac');

%go_aspect_colour = (C => '#afdfd5',
                     F => '#bcccfc',
                     P => '#dcccfc');

%go_aspect_href = (C => 'cellular_component',
                   F => 'molecular_function',
                   P => 'biological_process');

%go_aspect_title = (C => 'Cellular Component',
                    F => 'Molecular Function',
                    P => 'Biological Process');

%go_evid_colour = (IC  => '#ccecf5',
                   IDA => '#b5c5f5',
                   IEA => '#ff5555',
                   IEP => '#ffc5f5',
                   IGI => '#dcfcac',
                   IMP => '#bcecac',
                   IPI => '#ccecac',
                   ISS => '#ffd5fc',
                   NAS => '#fcfcdc',
                   ND  => '#e0e0e0',
                   RCA => '#fcdcec',
                   TAS => '#ccccfc',
                   NR  => '#cccccc');

%go_evid_title = (IC  => 'Inferred by Curator',
                  IDA => 'Inferred from Direct Assay',
                  IEA => 'Inferred from Electronic Annotation',
                  IEP => 'Inferred from Expression Pattern',
                  IGI => 'Inferred from Genetic Interaction',
                  IMP => 'Inferred from Mutant Phenotype',
                  IPI => 'Inferred from Physical Interaction',
                  ISS => 'Inferred from Sequence or Structural Similarity',
                  NAS => 'Non-traceable Author Statement',
                  ND  => 'No biological Data available',
                  RCA => 'inferred from Reviewed Computational Analysis',
                  TAS => 'Traceable Author Statement',
                  NR  => 'Not Recorded');

local $| = 1;

main();

1;


###############################################################################

sub make_gene_id {

    my $id = shift;

    $id = uc $id;

    $id =~ s/C$/c/
        if $id =~ /^SP.+C$/;

    return $id;

}


###############################################################################

sub connect_to_DB {

    my ($driver, $instance, $host, $port, $cnf_file, $user, $password) = @_;

    my $connect_string =
        "DBI:${driver}:database=${instance};host=${host};port=$port;" .
        "mysql_read_default_file=${cnf_file}";

    # TODO: should have DBI::errstr's in all queries!

    my $dbh = DBI->connect($connect_string, $user, $password)
        or die "ERROR: $DBI::errstr\n";

    if (not defined $dbh) {
        die "Could not connect to database: $DBI::errstr\n";
    }

    return $dbh;

}


###############################################################################

sub disconnect_from_DB {

    my $dbh = shift;

    $dbh->disconnect()
        or die "Could not disconnect from database: $DBI::errstr\n";

}


###############################################################################

sub test_query {

    my ($dbh) = @_;

    my $string = qq(SELECT *
                    FROM   pombe_gene
                    WHERE  GeneDB_primary = 'tea1');

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute();

    my @row = $sth_query->fetchrow_array();

    return;

}

###############################################################################

sub main {

    my $title = qq(YOGY: eukarYotic OrtholoGY);
    my $cgi   = CGI->new();
    my $sw    = SangerWeb->new({title => $title});

 #print $sw->header();
 print qq(Content-type: text/html\n\n);

print qq (<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>Bahler Lab</title>
<meta name="keywords" content="" />
<meta name="description" content="" />
<link href="/css/other.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="header">
<div style="text-align:left; margin-left:70px; margin-bottom:0px; margin-top:0px;"><span style="text-shadow:#FFF; font-family:'Arial Black', Gadget, sans-serif; font-size:32pt; color:#EBF1DE; ">b&auml;hler</span><span style="text-shadow:auto; font-family:'Arial Black', Gadget, sans-serif; font-size:32pt; color:#77933C; ">lab&#13;</span></div>
  <div style="text-align:left; margin-left:30px; margin-top:0px;"><span style="font-family:'Arial Black', Gadget, sans-serif; font-size:20pt; color:#4F6228; "> Genome Regulation</span></div>
  <div class="O">
  <div style="text-align:center; margin-bottom:0; margin-top:-76px; margin-left:120px;margin-right:-20px;"><span style="font-family:Arial, Helvetica, sans-serif; font-size:92pt; color:#D7E4BD; "><strong><em>yogy&#13;</em></strong></span></div>
<div style="text-align:right; margin-bottom:0; margin-top:-76px; margin-left:150px;margin-right:20px;"><span style="font-family:'Arial Black', Helvetica, sans-serif; font-size:36pt; color:white; ">UCL</span></div>
  <div></div>
</div>


</div>
);
    print ' ' x 2048;

   # print "<p>", table({-width => '100%',
    #                    -class => 'violet3'},
     #                  Tr({-align => 'center'},
      #                    td("<h2>YOGY:</h2><h3>eukarYotic OrtholoGY</h3>") )
       #               ), "</p>";

    undef my $id;
    undef my $gene_name;
    undef my $kog;

    if ($cgi->param() ) {

        my $name = $cgi->param('gene');
        ($name)  = $name =~ /([a-zA-Z0-9_\-\.;:,]+)/;

        print_help_bar();

        print
            "<p>", h4("Search term: $name"),
            hr({-align => 'left',
                -size  => '2',
                -width => '80%'});

        my $species = $cgi->param('species');

        my $wild_card = $cgi->param('wild');

        my $go_term = $cgi->param('go_term');

        my $go_final = $cgi->param('go_final');

        my $dbh = connect_to_DB('mysql', 'S_pombe_YOGY_2', 'localhost',
                                '3306', '', 'yogyro', '');

        #test_query($dbh);

        my $species_id = $species_id{$species};
        my $tax_id     = $species_tax_rev{$species_id};

        my $new_name = lc $name;

        # Is it a UniProt ID?

        if ($name =~ /^([OPQ][\d][A-Z\d]{3}\d)/i) {

            $uni_query = $name;

            my $tmp_id = '';

            if ($species eq 'S._pombe') {

                $tmp_id = get_pombe_id_from_uni($dbh, $uni_query);

            } elsif ($species eq 'C._elegans') {

                $tmp_id = get_worm_id_from_uni($dbh, $uni_query);

            } elsif ($species eq 'M._musculus') {

                $tmp_id = get_mouse_id_from_uni($dbh, $uni_query);

            } elsif ($species eq 'R._norvegicus') {

                $tmp_id = get_rat_id_from_uni($dbh, $uni_query);

            } elsif ($species eq 'H._sapiens') {

                $tmp_id = get_ens_from_uni($dbh, $uni_query, $species_id);

            } elsif ($species eq 'E.coli') {

                $tmp_id = get_eco_id_from_uni($dbh, $uni_query);

            }

            if (not defined $tmp_id or not $tmp_id) {

                $tmp_id = get_yogy_id($dbh, $uni_query);

            }

            $new_name = $tmp_id
                if defined $tmp_id and $tmp_id;

            #print "UNI: [$uni_query] [$new_name]\n";

        }

        # Is it a GI number?

        if ($name =~ /^(HsM?|GI:)?(\d+)$/) {

            $new_name = $2;

            my $tmp_id = get_id_from_gi($dbh, $new_name, $tax_id);

            if (defined $tmp_id and $tmp_id) {

                $gi_query = $name;

                $new_name = $tmp_id;

                my $tmp_id = get_ens_from_gi($dbh, $gi_query, $species_id);

                $ens_query = $tmp_id
                    if defined $tmp_id and $tmp_id;

                #get_ipi_info_from_gi($dbh, $new_name, $tax_id);

            }

        }

        #print "[$ens_query]\n";

        undef my $gene_info;

        # Is it an ENSEMBL ID?

        if ( ($name =~ /^ENS/ or
              $new_name =~ /^ENS/) and
            ($species eq 'H._sapiens' or
             $species eq 'M._musculus' or
             $species eq 'R._norvegicus') ) {

            if ($name =~ /^ENS/) {

                $ens_query = $name;

            } elsif ($new_name =~ /^ENS/) {

                $ens_query = $new_name;

            }

            $gene_info = get_info_from_ens($dbh, $ens_query, $species_id);

            $gi_query  = $gene_info->[1];
            $uni_query = $gene_info->[5];

            my $yogy_id = get_yogy_id($dbh, $gi_query);

            my $gene_id = get_id_from_gi($dbh, $gi_query, $tax_id);

            my $tmp_id = '';

            if ($species_id == 130) {

                $tmp_id = get_mouse_id($dbh, $gene_id);

            } elsif ($species_id == 150) {


                $tmp_id = get_rat_id($dbh, $gene_id);

            }

            if ($tmp_id) {

                $new_name = $tmp_id;

            }

            if ($species eq 'M._musculus' or $species eq 'R._norvegicus') {

                my $gene_info_new = get_gene_info($dbh, $new_name, $wild_card, $species);

                $gene_info = $gene_info_new
                    if defined $gene_info_new and defined $gene_info_new->[0];

            }

            #print "[$new_name] [$yogy_id] [$gene_id]\n";

        } else {

            if ($species eq 'M._musculus') {

                $new_name =~ s/^MGI://i;

            } elsif ($species eq 'R._norvegicus') {

                $new_name =~ s/^RGD://i;

            }

            $gene_info = get_gene_info($dbh, $new_name, $wild_card, $species);

            my @ens_query = get_ens_from_ids($dbh, $name, $species_id);

            if (scalar @ens_query > 1) {

                print
                    '<b>There are multiple Ensembl IDs for this gene: ';

                my $pflag = 1;

                foreach my $eid (@ens_query) {

                    if ($pflag == 1) {
                        $pflag = 0;
                    } else {
                        print ', ';

                    }

                    my $href = "http://www.sanger.ac.uk/cgi-bin/YOGY/yogy-search.pl?gene=${eid}&species=${species}&wild=${wild_card}&go_term=${go_term}&go_final=${go_final}";

                    print "<a href=$href>$eid</a>";

                }

                print '.'

            }

            $ens_query = $ens_query[0]
                if scalar @ens_query >= 1;

            if (not $ens_query) {

                my $tmp_id = get_gi_from_id($dbh, $gene_info->[1], $tax_id);

                #print "[TMP: $tmp_id]\n";

                my $tmp_id2 = get_ens_from_gi($dbh, $tmp_id, $species_id)
                    if defined $tmp_id and $tmp_id;

                $ens_query = $tmp_id2
                    if defined $tmp_id2 and $tmp_id2;

            }

            if ($ens_query and not $gene_info->[0]) {

                $gene_info = get_info_from_ens($dbh, $ens_query[0], $species_id);

            }

            #print "[$ens_query] [$name] [$species_id]\n";

        }

        #print Dumper $gene_info;

        if (not defined $gene_info or not defined $gene_info->[0]) {

            if ($wild_card eq 'Yes') {

                print
                    "<h5>There are no gene IDs or names that include '$name'.  </h5><br />",
                    "You can try to search again below.<br /><br />";

            } elsif ($wild_card eq 'No') {

                print
                    "<h5>'$name' is not recognised as a gene ID or name.  </h5><br />",
                    "You can search again below or try with the wild-card search option.<br /><br />";

            }

            disconnect_from_DB($dbh);

            print_help_bar();

            print_form();

            print_web_bar();

            exit -1;

        }

        if (scalar @{$gene_info} == 1 and

            ($new_name eq lc($gene_info->[0][0]) or
             $new_name eq lc($gene_info->[0][1]) ) ) {

            $wild_card = 'No';

            ($gene_info) = get_gene_info($dbh, $new_name, $wild_card, $species);

        }

        $uni_query = $gene_info->[5]
            if not defined $uni_query and not $uni_query;

        if ($wild_card eq 'Yes') {

            my @wildheadings = ('Result', 'Systematic ID', 'Primary name', 'Description');

            foreach my $wh (@wildheadings) {

                $wh = '<em>' . $wh . '</em>';

            }

            my @wildrows = td(\@wildheadings);

            my $count = 1;

            foreach my $nr (@{$gene_info}) {

                my $new_id = make_gene_id($nr->[0]);

                my $descrip = $nr->[2];

                if ($species eq 'C._elegans') {

                    $descrip = $nr->[4]
                        if not $descrip;

                }

                my $script_name = $ENV{SCRIPT_NAME};

                $script_name =~ s/\/\//\//g;

                my $href =
                    "${script_name}?gene=$new_id&wild=No&species=$species&go_term=$go_term&go_final=$go_final";

                push(@wildrows, td({-class => 'violet1',
                                    -align => 'center'},
                                   [$count,
                                    a({-href  => $href,
                                       -style => $gStyle},
                                      $new_id),
                                    $nr->[1],
                                    $descrip
                                   ]) );

                $count++;

            }

            print ' ' x 2048;

            print "<p>", table({-class       => 'violet3',
                                -cellpadding => '2'},
                               Tr(\@wildrows) ), "</p>";

            print hr({-align => 'left',
                      -size  => '2',
                      -width => '80%'});

        } elsif ($wild_card eq 'No') {

            my $new_id = $gene_info->[0];

            if ($species eq 'S._pombe') {

                $new_id = make_gene_id($new_id);

            } elsif ($species eq 'S._cerevisiae') {

                $new_id = make_gene_id($gene_info->[3]);

            }

            print "<p>", a({-name  => 'gene',
                            -style => $gNone},
                           h4('Gene summary: ') ), "</p>";

            print ' ' x 2048;

            print "<table class='violet3' cellpadding='4'><tr><td width='50%'>";

            my @data_check = do_summary($dbh, $new_id, $species, $go_term, $go_final, $gene_info);

            print "</td><td>";

            print_form();

            print "</td></tr></table>";

            print hr({-align => 'left',
                      -size  => '2',
                      -width => '80%'});

            if ($data_check[0] eq 'Y') {

                do_kogs($dbh, $new_id, $species, $go_term, $go_final, $gene_info);

            }

            if ($data_check[1] eq 'Y') {

                do_inparanoid($dbh, $new_id, $species, $go_term, $go_final, $gene_info);

            }

            if ($data_check[2] eq 'Y') {

                do_homologene($dbh, $new_id, $species, $go_term, $go_final, $gene_info);

            }

            if ($data_check[3] eq 'Y') {

                do_orthomcl($dbh, $new_id, $species, $go_term, $go_final, $gene_info);

            }

            if ($data_check[4] eq 'Y') {

                do_vals($dbh, $new_id, $species, $go_term, $go_final, $gene_info);

            }

            if ($go_final eq 'Yes' and $go_term eq 'Yes') {

                print_final_go_table($dbh);

                print_back_to_top();

            }

        }

        disconnect_from_DB($dbh);

    }

    print_help_bar();

    print_form();

    print_web_bar();
#print '</div</div>';
   # print $sw->footer();

    exit 0;

}


###############################################################################

sub do_summary {

    my ($dbh, $new_id, $species, $go_term, $go_final, $gene_info) = @_;

    my @data_check = db_data_check($dbh, $gene_info->[0], $gene_info->[1], $gene_info->[3], $species);

    undef my @namerows;

    my $href  = '';
    my $title = '';

    my $species_id = $species_id{$species};

    my $tax_id = $species_tax_rev{$species_id};

    my $tax_href = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$tax_id";

    push(@namerows, td({-align       => 'left',
                        -cellpadding => '2',
                        -width       => '5%'},
                       ['<em>Species</em>',
                        a({-href   => $tax_href,
                           -style  => $gStyle,
                           -target => $gBlank,
                           -title  => 'NCBI Taxonomy'},
                          $species_name{$species_id} . ' (' . $species_3let{$species_id} . ')')]) );

    my $sys_id = $gene_info->[0];

    my $descrip = $gene_info->[2];

    my $uni_id = '';
    my $ens_id = '';

    my $alt_db_id = '';

    if ($species eq 'S._pombe') {

        $sys_id = make_gene_id($sys_id);

        $href  = "http://old.genedb.org/genedb/Search?organism=S.+pombe&name=$sys_id";
        $title = 'GeneDB';

        $uni_id = get_pombe_uni_id($dbh, $sys_id);

    } elsif ($species eq 'S._cerevisiae') {

        $sys_id = make_gene_id($sys_id);

        $href  = "http://db.yeastgenome.org/cgi-bin/locus.pl?locus=$sys_id";
        $title = 'SGD';

        $alt_db_id = $new_id;

    } elsif ($species eq 'C._elegans') {

        $href  = "http://www.wormbase.org/db/gene/gene?name=$sys_id";
        $title = 'WormBase';

        $descrip = $gene_info->[4]
            if not $descrip;

        $uni_id = get_worm_uni_id($dbh, $sys_id);

        $alt_db_id = $gene_info->[3];

    } elsif ($species eq 'D._melanogaster') {

        if ($sys_id =~ /^\d+$/) {

            $href  = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?list_uids=$sys_id";
            $title = 'NCBI';

        } else {

            $href  = "http://flybase.net/cgi-bin/fbidq.html?$sys_id";
            $title = 'FlyBase';

        }

        $alt_db_id = $gene_info->[3];

    } elsif ($species eq 'A._thaliana') {

        my $arab_gi = get_arab_gi($dbh, $sys_id);

        $href  = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?list_uids=$arab_gi";
        $title = 'NCBI';

        #$href  = "http://www.arabidopsis.org/servlets/TairObject?type=locus&id=$arab_id";
        #$title = 'TAIR';

        $descrip = '';

    } elsif ($species eq 'M._musculus') {

        if ($sys_id !~ /^ENS/) {

            $href  = "http://www.informatics.jax.org/searches/accession_report.cgi?id=MGI:$sys_id";
            $title = 'MGI';

            $uni_id = get_mouse_uni_id($dbh, $sys_id);

            $sys_id = 'MGI:' . $sys_id;

            my @ens_id = get_ens_from_ids($dbh, $sys_id, $species_id);

            $ens_id = join ', ', @ens_id;

        }

    } elsif ($species eq 'R._norvegicus') {

        if ($sys_id !~ /^ENS/) {

            $href  = "http://rgd.mcw.edu/tools/genes/genes_view.cgi?id=$sys_id";
            $title = 'RGD';

            $uni_id = get_rat_uni_id($dbh, $sys_id);

            my @ens_id = get_ens_from_ids($dbh, $sys_id, $species_id);

            $ens_id = join ', ', @ens_id;

            $sys_id = 'RGD:' . $sys_id;

        }

    } elsif ($species eq 'P._falciparum') {

        $href  = "http://www.genedb.org/genedb/Search?organism=malaria&name=$sys_id";
        $title = 'GeneDB';

    } elsif ($species eq 'D._discoideum') {

        $href  = "http://dictybase.org/db/cgi-bin/gene_page.pl?dictybaseid=$sys_id";
        $title = 'dictyBase';

    } elsif ($species eq 'E._coli') {

        $href  = "http://ecogene.org/geneinfo.php?eg_id=$sys_id";
        $title = 'EcoGene';

    } elsif ($species eq 'H._sapiens') {

        if ($sys_id !~ /^ENS/) {

            $sys_id =~ s/^HsM?//;

            my $tmp_id = get_gi_from_id($dbh, $sys_id, $tax_id);

            $sys_id = $tmp_id
                if defined $tmp_id and $tmp_id;

            $href  = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?list_uids=$sys_id";
            $title = 'NCBI';

            $descrip = '';

            my @ens_id = get_ens_from_ids($dbh, $sys_id, $species_id);

            $ens_id = join ', ', @ens_id;

            #print "ENS: [$sys_id] [$ens_id]\n";

        }

    }

    if ($sys_id =~ /^ENS/) {

        $href  = "http://apr2005.archive.ensembl.org/$ensembl_species{$species_id}/protview?peptide=$sys_id";
        $title = 'Ensembl';

        $descrip = '';

        my $gene_name = get_name_from_ens($dbh, $ens_query, $species_id);

        $alt_db_id = (split /,/, $gene_name)[1];

    }

    $uni_id = get_uniprot_id2($dbh, $sys_id, $tax_id)
        if not defined $uni_id or not $uni_id;

    $uni_id = $uni_query
        if not defined $uni_id or not $uni_id;

    $uni_id = ''
        if not defined $uni_id;

    unless (defined $uni_query and $uni_query) {

        $uni_query = $uni_id
            if defined $uni_id and $uni_id;

    }

    unless (defined $ens_query and $ens_query) {

        my @ens_ids = split /, /, $ens_id;

        foreach my $ens_id2 (@ens_ids) {

            $ens_query = $ens_id
                if defined $ens_id and $ens_id;

        }

    }

    push(@namerows, td({-align => 'left'},
                       ['<em>Primary name</em>',
                        $gene_info->[1]]) );

    push(@namerows, td({-align       => 'left',
                        -cellpadding => '2'},
                       ["<em>$title link</em>",
                        a({-href   => $href,
                           -style  => $gStyle,
                           -target => $gBlank,
                           -title  => $title},
                          $sys_id)]) );

    if ($alt_db_id) {

        push(@namerows, td({-align => 'left'},
                           ['<em>Alternative ID</em>',
                            $alt_db_id]) );
    }

    $descrip = ''
        if not defined $descrip;

    if ($descrip) {

        push(@namerows, td({-align => 'left'},
                           ['<em>Description</em>', $descrip]) );

    }

    if ($uni_id) {

        $href = "http://www.expasy.org/cgi-bin/niceprot.pl?$gene_info->[5]";

        push(@namerows, td({-align => 'left'},
                           ['<em>UniProt link</em>',
                            a({-href   => $href,
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => 'UniProt'},
                              $uni_id)]) );

    }

    if ($ens_query) {

        if ($title ne 'Ensembl') {

            $href  = "http://apr2005.archive.ensembl.org/$ensembl_species{$species_id}/protview?peptide=$ens_query";

            push(@namerows, td({-align => 'left'},
                               ['<em>Ensembl link</em>',
                                a({-href   => $href,
                                   -style  => $gStyle,
                                   -target => $gBlank,
                                   -title  => 'Ensembl'},
                                  $ens_query)]) );

        }

    } elsif ($species eq 'H._sapiens' or
             $species eq 'M._musculus' or
             $species eq 'R._norvegicus') {

        push(@namerows, td({-align => 'left'},
                           ['<em>Ensembl link</em>',
                            "No Ensembl ID found for $sys_id"]) );

    }

    if ($species eq 'S._pombe' or 'D._discoideum') {

        my $synonyms = '';

        if ($species eq 'S._pombe') {

            my @synonyms = get_synonyms_pombe($dbh, $new_id);

            foreach my $syn (@synonyms) {

                $synonyms = $synonyms . $syn . ',  ';

            }

            $synonyms =~ s/,  $//;

        } else {

            $synonyms = $gene_info->[3];

        }

        push(@namerows, td({-align => 'left'},
                           ['<em>Synonyms</em>', $synonyms]) );

    }

    if ($species eq 'S._pombe') {

        my $href3 = "http://www.sanger.ac.uk/perl/SPGE/geexview?group=3&q=$new_id&scale=log2&scale_min=-2&scale_max=2";
        my $href2 = "http://www.sanger.ac.uk/perl/SPGE/geexview?group=2&q=$new_id&scale=linear&scale_auto=on";
        my $href1 = "http://www.sanger.ac.uk/perl/SPGE/geexview?group=1&q=$new_id&scale=linear&scale_auto=on";

        push(@namerows, td({-align => 'left'},
                           ['<em>Gene expression <br />profiles</em>',
                            "<a href=$href3 target=$gBlank title='Cell cycle'>" .
                            "<img src = '/YOGY/images/red_c.jpg' /></a> " .
                            "<a href=$href2 target=$gBlank title='Environmental stress'>" .
                            "<img src = '/YOGY/images/green_s.jpg' /></a> " .
                            "<a href=$href1 target=$gBlank title='Sexual differentiation'>" .
                            "<img src = '/YOGY/images/blue_m.jpg' /></a>"
                           ]) );

    }

    my $kog_href = "http://www.ncbi.nlm.nih.gov/COG/new/";
    my $inp_href = "http://inparanoid.sbc.su.se/";
    my $hom_href = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?DB=homologene";
    my $ort_href = "http://orthomcl.cbil.upenn.edu/";
    my $gdb_href = "http://www.sanger.ac.uk/Projects/S_pombe/";

    my $yes_img = '/YOGY/images/green_y.jpg';
    my $no_img  = '/YOGY/images/red_n.jpg';

    my $img1 = '';

    if ($data_check[0] eq 'Y') {

        $img1 = "<a href='#kog' title='KOGs results'><img src=$yes_img /></a>";

    } else {

        $img1 = "<img src=$no_img />";

    }

    my $img2 = '';

    if ($data_check[1] eq 'Y') {

        $img2 = "<a href='#inparanoid' title='Inparanoid results'><img src=$yes_img /></a>";

    } else {

        $img2 = "<img src=$no_img />";

    }

    my $img3 = '';

    if ($data_check[2] eq 'Y') {

        $img3 = "<a href='#homologene' title='HomoloGene results'><img src=$yes_img /></a>";

    } else {

        $img3 = "<img src=$no_img />";

    }

    my $img4 = '';

    if ($data_check[3] eq 'Y') {

        $img4 = "<a href='#orthomcl' title='OrthoMCL results'><img src=$yes_img /></a>";

    } else {

        $img4 = "<img src=$no_img />";

    }

    my $img5 = '';

    if ($data_check[4] eq 'Y') {

        $img5 = "<a href='#curated' title='Curated results'><img src=$yes_img /></a>";

    } else {

        $img5 = "<img src=$no_img />";

    }

    push(@namerows,
         td(["<em>Datasets</em>",
             "<table><tr><td>" .
             "<a href=$kog_href target=$gBlank title='KOGs' " .
             "style='$gStyle'>KOGs</a></td><td>$img1</td></tr>" .
             "<tr><td><a href=$inp_href target=$gBlank title='Inparanoid' " .
             "style='$gStyle'>Inparanoid</a></td><td>$img2</td></tr>" .
             "<tr><td><a href=$hom_href target=$gBlank title='HomoloGene' " .
             "style='$gStyle'>HomoloGene</a></td><td>$img3</td></tr>" .
             "<tr><td><a href=$ort_href target=$gBlank title='OrthoMCL' " .
             "style='$gStyle'>OrthoMCL</a></td><td>$img4</td></tr>" .
             "<tr><td><a href=$gdb_href target=$gBlank title='GeneDB' " .
             "style='$gStyle'>Curated</a></td><td>$img5</td></tr></table>"]) );

    print "<p>", table({-width       => '80%',
                        -cellpadding => '2',
                        -bgcolor     => $species_colour{$species_id} },
                       Tr(\@namerows) ), "</p>";

    return @data_check;

}


###############################################################################

sub do_kogs {

    my ($dbh, $new_id, $species, $go_term, $go_final, $gene_info) = @_;

    my $search_kog = $new_id;

    my $spec_id = $species_id{$species};

    if ($species eq 'C._elegans') {

        $search_kog = $gene_info->[0]
            if defined $gene_info->[0] and $gene_info->[0];

    } elsif ($species eq 'A._thaliana') {

        $search_kog =~ s/\.\d+$//;

    } elsif ($species eq 'D._melanogaster' or $species eq 'H._sapiens') {

        $search_kog = $gi_query;

        my $tax_id = $species_tax_rev{$spec_id};

        my $tmp_id = get_gi_from_id($dbh, $search_kog, $tax_id);

        if (defined $tmp_id and $tmp_id) {

            $search_kog = $tmp_id;

        } else {

            $tmp_id = get_gi_from_id($dbh, $gene_info->[1], $tax_id);

            if (defined $tmp_id and $tmp_id ) {

                $search_kog = $tmp_id;

            } else {

                $tmp_id = get_gi_from_id($dbh, $gene_info->[3], $tax_id);

                $search_kog = $tmp_id
                    if defined $tmp_id and $tmp_id;

            }

        }


    }

    my @kog_details = get_kogs_results($dbh, $search_kog, $spec_id);

    my @protein_id = get_prot_results($dbh, $kog_details[0]);

    my @kog_olc = split '', $kog_details[1];

    undef my $func_details;

    foreach my $ko (@kog_olc) {

        my @func_details = get_func_results($dbh, $ko);

        my $href1 = "/YOGY/function.shtml";
        my $href2 = "http://www.ncbi.nlm.nih.gov/COG/grace/shokog.cgi?fun=$ko";

        $func_details .=
            "<a href=$href1 style='$gStyle' target=$gBlank " .
            "title='KOGs classification explained'>" .
            $ko . "</a><br />" . $func_details[2] . "<br />" .
            "<a href=$href2 style='$gStyle' target=$gBlank " .
            "title='Other KOGs in this functional group'>" .
            $func_details[1] . "</a><br />";

    }

    undef my $species_count;

    foreach my $prot (@protein_id) {

        $species_count->{$prot->[1]}++;

    }

    my ($phystring, $phylink, @values) = phy_info($species_count);

    undef my @keys;

    foreach my $kid (@kogs_species_id) {

        push @keys, $species_3let{$kid}

    }

    my $first_kc = substr $kog_details[1], 0, 1;

    my $kog_colour = $function_colour{$first_kc};

    my @kogheadings = td({-style => 'font-style: italic'},
                         ['KOG name',
                          'Phylogenetic pattern <br />(and link to KOGs with this pattern)']);

    undef my @kogrows;

    my $href1 = "http://www.ncbi.nlm.nih.gov/COG/grace/shokog.cgi?$kog_details[0]";
    my $href2 = "http://www.ncbi.nlm.nih.gov/COG/grace/shokog.cgi?phy=$phylink";

    my $graph = draw_kogs_graph(\@keys, \@values);
    #my $graph = '';

    my $gr_href = "$TMPURI/$graph";

    push(@kogrows, td({-align   => 'center',
                       -bgcolor => $kog_colour},
                      [a({-href   => $href1,
                          -style  => $gStyle,
                          -target => $gBlank,
                          -title  => 'NCBI KOG page'},
                         $kog_details[0]),
                       a({-href   => $href2,
                          -style  => $gStyle,
                          -target => $gBlank,
                          -title  => 'Other KOGs with this pattern'},
                         $phystring) . ("<br />") .
                       "<a href=$href2 style='$gStyle' target=$gBlank " .
                       "title = 'Other KOGs with this pattern'>" .
                       "<img src=$gr_href /></a>"]) );

    my @kogheadings2 = td({-style => 'font-style: italic'},
                          ['KOGs classification',
                           'KOGs description']);

    undef my @kogrows2;

    push(@kogrows2, td({-align   => 'center',
                        -bgcolor => $kog_colour},
                       [$func_details,
                        $kog_details[2] ]) );

    undef my @orthrows;

    my @orthheadings = td({-align => 'center',
                           -style => 'font-style: italic'},
                          ['Species',
                           'KOG link',
                           'NCBI link',
                           'UniProt link']
                         );

    undef my $local_search_gos;

    foreach my $prot (@protein_id) {

        my $species_id = $prot->[1];

        my $search_id = $prot->[2];

        my $gi = $prot->[3];

        my $tmp_id = '';

        if ($species_id == 30 or $species_id == 40) {

            my $tax_id = $species_tax_rev{$species_id};

            $tmp_id = get_id_from_gi($dbh, $gi, $tax_id);

        } elsif ($species_id == 50) {

            $tmp_id = get_budding_id($dbh, $search_id);

        }

        if ($tmp_id) {

            $search_id = $tmp_id;

        }

        if ($species_id == 30) {

            $tmp_id = get_fly_id($dbh, $search_id);

        }

        if ($tmp_id) {

            $search_id = $tmp_id;

        }

        my $uni_id = get_uniprot_id2($dbh, $gi, $species_tax_rev2{$species_id});

        my $search_uni = $search_id;

        $search_uni =~ s/_\d+$//;

        my $tmp_uni_id = '';

        if ($species_id == 60) {

            $tmp_uni_id = get_pombe_uni_id($dbh, $search_uni);

        } elsif ($species_id == 20) {

            $tmp_uni_id = get_worm_uni_id($dbh, $search_uni);

        }

        if ($tmp_uni_id) {

            $uni_id = $tmp_uni_id;

        }

        if ($go_term eq 'Yes') {

            my $search_go = $search_id;

            $search_go =~ s/_\d+$//;

            my $uni_go_id = $uni_id;

            $uni_go_id =~ s/\-\d+$//;

            $local_search_gos = search_go_with_ids($dbh, $search_go, $uni_go_id, $species_id, $local_search_gos);

        }

        my $href1 = "http://www.ncbi.nlm.nih.gov/COG/grace/bluk.cgi?cog=$prot->[0]&$prot->[2]";
        my $href2 = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&val=$prot->[3]";
        my $href3 = "http://www.expasy.org/cgi-bin/niceprot.pl?$uni_id";

        if ($species_id == 20) {

            $tmp_id = get_worm_gid($dbh, $search_id);

            if ($tmp_id) {

                $search_id = $tmp_id;

            }

        }

        if ($prot->[2] ne $search_id) {

            $search_id = $prot->[2] . ' <br>(' . $search_id . ')';

        }

        my $tax_id = $species_tax_rev{$species_id};

        my $tax_href = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$tax_id";

        push(@orthrows, td({-align   => 'center',
                            -bgcolor => $species_colour{$species_id} },
                           [a({-href   => $tax_href,
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => 'NCBI Taxonomy'},
                              $species_name{$species_id} . ' (' . $species_3let{$species_id} . ')'),
                            a({-href   => $href1,
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => 'KOG alignment'},
                              $search_id),
                            a({-href   => $href2,
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => 'NCBI protein page'},
                              'GI:' . $prot->[3]),
                            a({-href   => $href3,
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => 'UniProt'},
                              $uni_id)
                           ]) );

    }

    print "<p>", a({-name  => 'kog',
                    -style => $gNone},
                   h4('KOG results: ') ), "</p>";

    undef my @kog;

    push @kog, @kogheadings;
    push @kog, @kogrows;

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2',
                        -bgcolor     => $kog_colour},
                       Tr(\@kog) ), "</p>";

    undef my @kog2;

    push @kog2, @kogheadings2;
    push @kog2, @kogrows2;

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2',
                        -width       => '60%',
                        -bgcolor     => $kog_colour},
                       Tr(\@kog2) ), "</p>";

    undef my @kog3;

    push @kog3, @orthheadings;
    push @kog3, @orthrows;

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                        Tr(\@kog3) ), "</p>";

    if ($go_final eq 'No' and $go_term eq 'Yes') {

        print_go_table($dbh, 'KOG', $local_search_gos);

    }

    print_back_to_top();

}


###############################################################################

sub do_inparanoid {

    my ($dbh, $new_id, $species, $go_term, $go_final, $gene_info) = @_;

    my $search_inp = $new_id;

    if ($species eq 'S._cerevisiae') {

        $search_inp = $gene_info->[0];

    } elsif ($species eq 'A._thaliana') {

        $search_inp = $gene_info->[1];

        $search_inp =~ s/\.\d+$//;

    } elsif ($species eq 'C._elegans') {

        $search_inp = $gene_info->[3];

    } elsif ($species eq 'H._sapiens') {

        $search_inp = $ens_query;

    } elsif ($species eq 'E._coli') {

        my $tmp_id = get_eco_ref_acc($dbh, $gene_info->[0]);

        $search_inp = $tmp_id, $search_inp =~ s/\.\d+$//
            if defined $tmp_id and $tmp_id;

    }

    my @inparanoid_results = get_inparanoid_results($dbh, $search_inp, $species);

    # Selected organisms for Inparanoid.

    my @inpara_keys = qw(ensAG ensCF ensDR ensFR ensGG ensHS ensMM ensPT ensRN modCE
                         modDD modDM modMM modOG modRR modSC modSP ncbAT ncbEC sanPF);

    # Not in KOGs or Homologene - so exclude.

    my @inpara_keys_excl = qw(ensAM ensCE ensDM ensTN modCB modDP);

    undef my @inpara_keys2;

    foreach my $inkey (@inpara_keys) {

        if ($inkey eq 'ensMM') {

            push @inpara_keys2, 'EMM';

        } elsif ($inkey eq 'ensRN') {

            push @inpara_keys2, 'ERN';

        } else {

            push @inpara_keys2, $species_3let{$inparanoid_species{$inkey} };

        }

    }

    undef my @inpara;

    undef my @prot_ids;

    undef my $ortholog_count;
    undef my $species_count;

    undef my %inparanoid_count;

    undef my $local_search_gos;

    my $search_db = '';

 PROT:
    foreach my $prot (@inparanoid_results) {

        #print "[$species_tax_rev{$inparanoid_species{$prot->[2]} }]\n";

        my $species_id = $inparanoid_species{$prot->[2]};

        my $search_id = $prot->[5];

        my $key_flag = 0;

        foreach my $key (@inpara_keys) {

            $key_flag = 1
                if $key eq $prot->[2];

        }

        next
            if $key_flag == 0;

        foreach my $excl (@inpara_keys_excl) {

            if ($excl eq $prot->[3]) {

                next PROT;

            }

        }

        my $pid_flag = 0;

    PID:
        foreach my $pid (@prot_ids) {

            if ($search_id eq $pid) {

                $pid_flag = 1;

                last PID;

            }

        }

        if ($pid_flag == 0) {

            $inparanoid_count{$prot->[2]}++;

        }

        if ($species_id eq $species_id{$species}) {

            push @prot_ids, $search_id;

        }

        my $uni_id = '';

        my $href  = '';
        my $title = '';

        my $gene_name = '';

        if ($prot->[2] =~ /^ens/) {

            $href  = "http://dec2004.archive.ensembl.org/$ensembl_species{$species_id}/protview?peptide=$search_id";
            $title = 'Ensembl';

            my $gene_info = get_info_from_ens($dbh, $search_id, $species_id);

            $uni_id = $gene_info->[5];

            $gene_name = get_name_from_ens($dbh, $search_id, $species_id);

            if ($prot->[2] eq 'ensMM' or $prot->[2] eq 'ensRN') {

                $gene_name = (split /,/, $gene_name)[0];

                $search_id = $gene_name
                    if defined $gene_name and $gene_name;

            } else {

                $gene_name = (split /,/, $gene_name)[1];

            }

        } elsif ($prot->[2] =~ /^swt/) {

            $href  = "http://us.expasy.org/cgi-bin/niceprot.pl?$search_id";
            $title = 'UniProt';

        } elsif ($prot->[2] eq 'sanPF') {

            $href  = "http://old.genedb.org/genedb/Search?organism=malaria&name=$search_id";

            $title = 'GeneDB';

        } elsif ($prot->[2] eq 'ncbEC') {

            $href  = "http://ecogene.org/geneinfo.php?eg_id=$search_id";
            $title = 'EcoGene';

            $uni_id = get_eco_uni_id($dbh, $search_id);

        } elsif ($prot->[2] =~ /^ncb/) {

            my $tax_id = $species_tax_rev{$species_id};

            $href  = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?list_uids=$search_id";
            $title = 'NCBI';

            my $prot_id = get_prot_id($dbh, $search_id, $tax_id);

            $uni_id = get_uniprot_id2($dbh, $prot_id, $tax_id);

        } elsif ($prot->[2] eq 'modCB' or $prot->[2] eq 'modCE') {

            my $tmp_id = get_worm_pid($dbh, $search_id);

            if ($tmp_id) {

                $search_id = $tmp_id;

            }

            $href  = "http://www.wormbase.org/db/gene/gene?name=$search_id";
            $title = 'WormBase';

            $uni_id = get_worm_uni_id($dbh, $search_id);

        } elsif ($prot->[2] eq 'modSP') {

            $href  = "http://old.genedb.org/genedb/Search?organism=S.+pombe&name=$search_id";

            $title = 'GeneDB';

            $uni_id = get_pombe_uni_id($dbh, $search_id);

        } elsif ($prot->[2] eq 'modSC') {

            $href  = "http://db.yeastgenome.org/cgi-bin/locus.pl?locus=$search_id";
            $title = 'SGD';

        } elsif ($prot->[2] eq 'modDD') {

            $href  = "http://dictybase.org/db/cgi-bin/gene_page.pl?dictybaseid=$search_id";
            $title = 'dictyBase';

        } elsif ($prot->[2] eq 'modDM') {

            $href  = "http://flybase.net/cgi-bin/fbidq.html?$search_id";
            $title = 'FlyBase';

        } elsif ($prot->[2] eq 'modDP') {

            $href  = "http://flybase.net/cgi-bin/gbrowse_fb/dpse?id=$search_id";
            $title = 'FlyBase';

        } elsif ($prot->[2] eq 'modMM') {

            $href  = "http://www.informatics.jax.org/searches/accession_report.cgi?id=MGI:$search_id";
            $title = 'MGI';

            $uni_id = get_mouse_uni_id($dbh, $search_id);

        } elsif ($prot->[2] eq 'modOG') {

            $href  = "http://www.gramene.org/db/protein/protein_search?acc=$search_id";
            $title = 'Gramene';

            $uni_id = $search_id;

        } elsif ($prot->[2] eq 'modRR') {

            $href  = "http://rgd.mcw.edu/tools/genes/genes_view.cgi?id=$search_id";
            $title = 'RGD';

            $uni_id = get_rat_uni_id($dbh, $search_id);

        }

        my $tmp_id = '';

        if ($prot->[2] eq 'modDM') {

            ($tmp_id = $search_id) =~ s/\-(\S+)$//;

            $tmp_id = get_fly_id($dbh, $tmp_id);

        } elsif ($prot->[2] eq 'ncbAT') {

            $tmp_id = get_arab_id($dbh, $search_id);

        }

        if ($tmp_id) {

            $search_id = $tmp_id;

        }

        if ($prot->[0] eq 'query') {

            if (not defined $uni_id and not $uni_id) {

                $uni_id = $uni_query
                    if defined $uni_query and $uni_query;

            }

            $search_db = $prot->[2];

        }

        if ($go_term eq 'Yes') {

            my $search_go = $search_id;

            if ($prot->[2] eq 'modMM') {

                $search_go = 'MGI:' . $search_go;

            } elsif ($prot->[2] eq 'modRR') {

                $search_go = 'RGD:' . $search_go;

            }

            my $uni_go_id = $uni_id;

            $uni_go_id =~ s/\-\d+$//;

            $local_search_gos = search_go_with_ids($dbh, $search_go, $uni_go_id, $species_id, $local_search_gos);

        }

        if ($prot->[5] ne $search_id) {

            $search_id = $prot->[5] . ' <br>(' . $search_id . ')';

        } elsif ($gene_name) {

            $search_id = $prot->[5] . ' <br>(' . $gene_name . ')';

        } elsif ($prot->[2] eq 'modSC') {

            $tmp_id = get_budding_id2($dbh, $search_id);

            if ($tmp_id) {

                $search_id = $search_id . ' <br>(' . $tmp_id . ')';

            }

        } elsif ($prot->[2] eq 'ncbEC') {

            $tmp_id = get_eco_id($dbh, $search_id);

            if ($tmp_id) {

                $search_id = $search_id . ' <br>(' . $tmp_id . ')';

            }

        }

        if ($prot->[2] eq 'modMM') {

            $search_id = 'MGI:' . $search_id;

        } elsif ($prot->[2] eq 'modRR') {

            $search_id = 'RGD:' . $search_id;

        }

        my $href2 = "http://inparanoid.sbc.su.se/cgi-bin/text_search.cgi?words=$prot->[5]&all_or_selection=all&specieslist=30";
      # my $href2 = "http://inparanoid.sbc.su.se/cgi-bin/text_search.cgi?words=$prot->[5]&all_or_selection=selection&specieslist=$prot->[2]";

        my $href3 = "http://www.expasy.org/cgi-bin/niceprot.pl?$uni_id";

        my $tax_id = $species_tax_rev{$species_id};

        my $tax_href = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$tax_id";

        my $species_tlc = '';

        if ($prot->[2] eq 'ensMM') {

            $species_tlc = 'EMM';

        } elsif ($prot->[2] eq 'ensRN') {

            $species_tlc = 'ERN';

        } else {

            $species_tlc = $species_3let{$species_id};

        }

        push(@inpara, td({-align   => 'center',
                          -bgcolor => $species_colour{$species_id} },
                         [a({-href   => $tax_href,
                             -style  => $gStyle,
                             -target => $gBlank,
                             -title  => 'NCBI Taxonomy'},
                            $species_name{$species_id} . ' (' . $species_tlc . ')'),
                          a({-href   => $href2,
                             -style  => $gStyle,
                             -target => $gBlank,
                             -title  => $prot->[3]},
                            $prot->[0]),
                          $prot->[4],
                          a({-href   => $href,
                             -style  => $gStyle,
                             -target => $gBlank,
                             -title  => $title},
                            $search_id),
                          a({-href   => $href3,
                             -style  => $gStyle,
                             -target => $gBlank,
                             -title  => 'UniProt'},
                            $uni_id)]) );

    }

    undef my @inpara_values;

    foreach my $key (@inpara_keys) {

        #print "[$key]\n";

        if (exists $inparanoid_count{$key}) {

            push @inpara_values, $inparanoid_count{$key};

        } else {

            push @inpara_values, 0;

        }

    }

    print "<p>", a({-name  => 'inparanoid',
                    -style => $gNone},
                   h4('Inparanoid results: ') ), "</p>", "<b>Selected databases only</b><br />";

    my $graph = draw_inparanoid_graph(\@inpara_keys2, \@inpara_values);
    #my $graph = '';

    undef my @inparanoidheadings;

    push(@inparanoidheadings, td({-align => 'center',
                                  -style => 'font-style: italic'},
                                 ['Inparanoid query cluster',
                                  'Phylogenetic pattern']) );

    my $href1 = "http://inparanoid.sbc.su.se/cgi-bin/text_search.cgi?words=$search_inp&all_or_selection=all&specieslist=30";

    push(@inparanoidheadings, td({-align   => 'center'},
                                 [a({-href   => $href1,
                                     -style  => $gStyle,
                                     -target => $gBlank,
                                     -title  => 'Query cluster page'},
                                    $search_inp),
                                  "<img src = $TMPURI/$graph />"]) );

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@inparanoidheadings) ), "</p>";

    undef my @inparanoidheadings2;

    push(@inparanoidheadings2, td({-align => 'center',
                                   -style => 'font-style: italic'},
                                  ['Species',
                                   'Link to cluster',
                                   'Score',
                                   'Model organism <br />protein page',
                                   'UniProt link']) );

    undef my @inparanoid;

    push @inparanoid, @inparanoidheadings2;

    push @inparanoid, @inpara;

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@inparanoid) ), "</p>";

    if ($go_final eq 'No' and $go_term eq 'Yes') {

        print_go_table($dbh, 'Inparanoid', $local_search_gos);

    }

    print_back_to_top();

}


###############################################################################

sub do_homologene {

    my ($dbh, $new_id, $species, $go_term, $go_final, $gene_info) = @_;

    my $search_hom = $gene_info->[1];

    my @homologene_results = get_homologene_results($dbh, $new_id, $search_hom, $species);

    my @homologene_keys = qw(Hsa Ptr Cfa Mmu Rno Gga Dme Aga Cel
                             Spo Sce Kla Ego Mgr Ncr Ath Osa Pfa);

    my @homologene_keys_excl = qw();

    undef my %homologene_count_hash;

    undef my @homologene;
    undef my @hom;

    my $HID = '';

    undef my $local_search_gos;

    #print "[@homologene_results]\n";

 PROT:
    foreach my $prot (@homologene_results) {

        $HID = $prot->[0];

        my $species_id = $species_tax{$prot->[1]};

        my $species_tlc = $species_3let{$species_id};

        my $search_id = $prot->[3];

        my $gi = $prot->[4];

        my $key_flag = 0;

        foreach my $key (@homologene_keys) {

            $key_flag = 1
                if $key eq $species_tlc;

        }

        next
            if $key_flag == 0;

        foreach my $excl (@homologene_keys_excl) {

            if ($excl eq $species_tlc) {

                next PROT;

            }

        }

        $homologene_count_hash{$species_tlc}++;

        my $tmp_id = '';

        if ($species_id == 20) {

            $tmp_id = get_worm_pid($dbh, $search_id);

        } elsif ($species_id == 30) {

            $tmp_id = get_fly_id($dbh, $search_id);

        } elsif ($species_id == 50) {

            $tmp_id = get_budding_id($dbh, $search_id);

        } elsif ($species_id == 60) {

            $tmp_id = make_gene_id(get_pombe_id($dbh, $search_id) );

        } elsif ($species_id == 130) {

            $tmp_id = get_mouse_id($dbh, $search_id);

        } elsif ($species_id == 150) {

            $tmp_id = get_rat_id($dbh, $search_id);

        }

        if ($tmp_id) {

            $search_id = $tmp_id;

        }

        my $uni_id = get_uniprot_id2($dbh, $gi, $species_tax_rev2{$species_id});

        my $tmp_uni_id = '';

        if ($species_id == 60) {

            $tmp_uni_id = get_pombe_uni_id($dbh, $search_id);

        } elsif ($species_id == 130) {

            $tmp_uni_id = get_mouse_uni_id($dbh, $search_id);

        } elsif ($species_id == 150) {

            $tmp_uni_id = get_rat_uni_id($dbh, $search_id);

        } elsif ($species_id == 20) {

            $tmp_uni_id = get_worm_uni_id($dbh, $search_id);

        }

        if ($tmp_uni_id) {

            $uni_id = $tmp_uni_id;

        }

        if ($go_term eq 'Yes') {

            my $search_go = $search_id;

            if ($species_id == 130) {

                $search_go = 'MGI:' . $search_go;

            } elsif ($species_id == 150) {

                $search_go = 'RGD:' . $search_go;

            }

            my $uni_go_id = $uni_id;

            $uni_go_id =~ s/\-\d+$//;

            $local_search_gos = search_go_with_ids($dbh, $search_go, $uni_go_id, $species_id, $local_search_gos);

        }

        my $href  = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&val=$prot->[4]";
        my $href2 = "http://www.expasy.org/cgi-bin/niceprot.pl?$uni_id";

        $tmp_id = '';

        if ($species_id == 20) {

            $tmp_id = get_worm_gid($dbh, $search_id);

            if ($tmp_id) {

                if ($search_id and $prot->[3] !~ /^CE/) {

                    $search_id = $search_id . '; <br>' . $tmp_id;

                } else {

                    $search_id = $tmp_id;

                }

            }

        }

        if ($prot->[3] ne $search_id) {

            if ($species_id == 130) {

                $search_id = 'MGI:' . $search_id;

            } elsif ($species_id == 150) {

                $search_id = 'RGD:' . $search_id;

            }

            $search_id = $prot->[3] . ' <br>(' . $search_id . ')';

        }

        my $tax_id = $species_tax_rev{$species_id};

        my $tax_href = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$tax_id";

        my $gene_href = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&cmd=Retrieve&dopt=Graphics&list_uids=$prot->[2]";

        push(@homologene, td({-align   => 'center',
                              -bgcolor => $species_colour{$species_id} },
                             [a({-href   => $tax_href,
                                 -style  => $gStyle,
                                 -target => $gBlank,
                                 -title  => 'NCBI Taxonomy'},
                                $species_name{$species_id} . ' (' . $species_3let{$species_id} . ')'),
                              a({-href   => $gene_href,
                                 -style  => $gStyle,
                                 -target => $gBlank,
                                 -title  => 'NCBI gene page'},
                                $search_id),
                              a({-href   => $href,
                                 -style  => $gStyle,
                                 -target => $gBlank,
                                 -title  => 'NCBI protein page'},
                                'GI:' . $prot->[4]),
                              a({-href   => $href2,
                                 -style  => $gStyle,
                                 -target => $gBlank,
                                 -title  => 'UniProt'},
                                $uni_id)
                             ]) );

    }

    undef my @homologene_values;

    foreach my $key (@homologene_keys) {

        #print "[$key]\n";

        if (exists $homologene_count_hash{$key}) {

            push @homologene_values, $homologene_count_hash{$key};

        } else {

            push @homologene_values, 0;

        }

    }

    print "<p>", a({-name  => 'homologene',
                    -style => $gNone},
                   h4('HomoloGene results: ') ), "</p>";

    my $graph = draw_homologene_graph(\@homologene_keys, \@homologene_values);
    #my $graph = '';

    my $href = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=homologene&dopt=Homologene&list_uids=$HID";

    undef my @hom;

    push(@hom, td({-align => 'center',
                   -style => 'font-style: italic'},
                  ['HomoloGene cluster',
                   'Phylogenetic pattern']) );

    push(@hom, td({-align   => 'center'},
                  [a({-href   => $href,
                      -style  => $gStyle,
                      -target => $gBlank,
                      -title  => 'HomoloGene cluster page'},
                     $HID),
                   "<img src = $TMPURI/$graph />"]) );

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@hom) ), "</p>";

    undef my @hom2;

    push(@hom2, td({-align => 'center',
                    -style => 'font-style: italic'},
                   ['Species',
                    'Gene ID',
                    'NCBI link',
                    'UniProt link']) );

    push @hom2, @homologene;

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@hom2) ), "</p>";

    if ($go_final eq 'No' and $go_term eq 'Yes') {

        print_go_table($dbh, 'Homologene', $local_search_gos);

    }

    print_back_to_top();

}


###############################################################################

sub do_orthomcl {

    my ($dbh, $new_id, $species, $go_term, $go_final, $gene_info) = @_;

    my $search_orth = $new_id;

    if ($species eq 'S._cerevisiae') {

        $search_orth = $gene_info->[3];

    } elsif ($species eq 'C._elegans') {

        my $tmp_id = get_worm_wid($dbh, $gene_info->[3]);

        if (defined $tmp_id and $tmp_id) {

            $search_orth = $tmp_id;

        } else {

            my $tmp_id = get_worm_wid2($dbh, $gene_info->[0]);

            $search_orth = $tmp_id
                if defined $tmp_id and $tmp_id;

        }

    } elsif ($species eq 'H._sapiens'  or
             $species eq 'M._musculus' or
             $species eq 'R._norvegicus') {

        $search_orth = $ens_query;

        $search_orth = ' '
            if not $search_orth;

    } elsif ($species eq 'E._coli') {

        my $tmp_id = get_eco_ref_gi($dbh, $gene_info->[0]);

        $search_orth = $tmp_id
            if defined $tmp_id and $tmp_id;

    }

    #print "[$search_orth]\n";

    my $orthomcl_cluster = get_orthomcl_cluster($dbh, $search_orth, $species);

    my @orthomcl_results = get_orthomcl_results($dbh, $orthomcl_cluster);

    # Selected organisms for OrthoMCL.

    my @orthomcl_keys = qw(Aga Ago Ath Cel Cgl Cne Ddi Dha
                           Dme Dre Eco Ecu Fru Gga Hsa Kla
                           Mmu Ncr Osa Pfa Rno Sce Spo Yli);

    my @orthomcl_keys_excl = qw(Hal Mja Sso Neq Wsu Gsu Atu Rso
                                Aae Tma Det Dra Tpa Cte Rba Cpn
                                Syn Mtu Ban Ehi Cme Tps Tgo Cpa
                                Cho Pyo Pkn The Cbr Cin Tni);

    undef my @ortho;

    undef my @oprot_ids;

    undef my %orthomcl_count_hash;

    undef my $local_search_gos;

 PROT:
    foreach my $prot (@orthomcl_results) {

        $prot->[1] = ucfirst $prot->[1];

        my $species_id = $species_3let_rev{$prot->[1]};

        my $search_id = $prot->[0];

        my $key_flag = 0;

        foreach my $key (@orthomcl_keys) {

            $key_flag = 1
                if $key eq $prot->[1];

        }

        next
            if $key_flag == 0;

        foreach my $excl (@orthomcl_keys_excl) {

            if ($excl eq $prot->[1]) {

                next PROT;

            }

        }

        $orthomcl_count_hash{$prot->[1]}++;

        my $uni_id = '';

        my $href  = '';
        my $title = '';

        my $gene_name = '';

        if ($prot->[1] eq 'Aga' or
            $prot->[1] eq 'Dre' or
            $prot->[1] eq 'Fru' or
            $prot->[1] eq 'Gga' or
            $prot->[1] eq 'Hsa' or
            $prot->[1] eq 'Mmu' or
            $prot->[1] eq 'Rno' or
            $prot->[1] eq 'Tni') {

            $href  = "http://apr2005.archive.ensembl.org/$ensembl_species{$species_id}/protview?peptide=$search_id";
            $title = 'Ensembl';

            my $gene_info = get_info_from_ens($dbh, $search_id, $species_id);

            $uni_id = $gene_info->[5];

            $gene_name = get_name_from_ens($dbh, $search_id, $species_id);

            if ($prot->[1] eq 'Mmu' or $prot->[1] eq 'Rno') {

                $gene_name = (split /,/, $gene_name)[0];

                $search_id = $gene_name
                    if defined $gene_name and $gene_name;

            } else {

                $gene_name = (split /,/, $gene_name)[1];

            }

        } elsif ($prot->[1] eq 'Pfa') {

            $href  = "http://old.genedb.org/genedb/Search?organism=malaria&name=$search_id";
            $title = 'GeneDB';

        } elsif ($prot->[1] eq 'Eco') {

            $href  = "http://ecogene.org/geneinfo.php?eg_id=$search_id";
            $title = 'EcoGene';

            $uni_id = get_eco_uni_id($dbh, $search_id);

        } elsif ($prot->[1] eq 'Ecu') {

            my $tax_id = $species_tax_rev{$species_id};

            $href  = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?list_uids=$search_id";
            $title = 'NCBI';

            (my $new_search_id = $search_id) =~ s/\.\d+$//;

            my $prot_id = get_prot_id($dbh, $new_search_id, $tax_id);

            $uni_id = get_uniprot_id2($dbh, $prot_id, $tax_id);

        } elsif ($prot->[1] eq 'Cel' or $prot->[1] eq 'Cbr') {

            my $tmp_id = get_worm_pid($dbh, $search_id);

            if ($tmp_id) {

                $search_id = $tmp_id;

            }

            $href  = "http://www.wormbase.org/db/gene/gene?name=$search_id";
            $title = 'WormBase';

            $uni_id = get_worm_uni_id($dbh, $search_id);

        } elsif ($prot->[1] eq 'Spo') {

            $href  = "http://old.genedb.org/genedb/Search?organism=S.+pombe&name=$search_id";
            $title = 'GeneDB';

            $uni_id = get_pombe_uni_id($dbh, $search_id);

        } elsif ($prot->[1] eq 'Sce') {

            $href  = "http://db.yeastgenome.org/cgi-bin/locus.pl?locus=$search_id";
            $title = 'SGD';

        } elsif ($prot->[1] eq 'Ddi') {

            $href  = "http://dictybase.org/db/cgi-bin/gene_page.pl?dictybaseid=$search_id";
            $title = 'dictyBase';

        } elsif ($prot->[1] eq 'Dme') {

            $href  = "http://flybase.net/cgi-bin/fbidq.html?$search_id";
            $title = 'FlyBase';

        } elsif ($prot->[1] eq 'Osa') {

            #$href  = "http://www.gramene.org/db/protein/protein_search?acc=$search_id";
            #$title = 'Gramene';

        } elsif ($prot->[1] eq 'Ath') {

            $href  = "http://www.arabidopsis.org/servlets/TairObject?type=gene&name=$search_id";
            $title = 'TAIR';

        } elsif ($prot->[1] eq 'Ago' or
                 $prot->[1] eq 'Cgl' or
                 $prot->[1] eq 'Kla') {

            $href  = "http://wolfe.gen.tcd.ie/cgi/browser/browser.pl?win=7&gene=$search_id";
            $title = 'Yeast Gene Order Browser';

        } elsif ($prot->[1] eq 'Cne') {

            $href  = "http://www.genome.jp/dbget-bin/www_bget?cne:$search_id";
            $title = 'KEGG';

        } elsif ($prot->[1] eq 'Dha') {

            $href  = "http://cbi.labri.fr/Genolevures/elt/DEHA/$search_id";
            $title = 'Genolevures';

        } elsif ($prot->[1] eq 'Yli') {

            $href  = "http://cbi.labri.fr/Genolevures/elt/YALI/$search_id";
            $title = 'Genolevures';

        }

        my $tmp_id = '';

        if ($prot->[1] eq 'Sce') {

            $tmp_id = uc(get_budding_id($dbh, $search_id) );

        } elsif ($prot->[1] eq 'Dme') {

            ($tmp_id = $search_id) =~ s/\-(\S+)$//;

            $tmp_id = get_fly_id($dbh, $tmp_id);

        } elsif ($prot->[1] eq 'Ath') {

            $tmp_id = get_arab_id($dbh, $search_id);

        } elsif ($prot->[1] eq 'Cel') {

            $tmp_id = get_worm_pid2($dbh, $search_id);

        }

        if ($tmp_id) {

            $search_id = $tmp_id;

        }

        if ($go_term eq 'Yes') {

            my $search_go = $search_id;

            my $uni_go_id = $uni_id;

            $uni_go_id =~ s/\-\d+$//;

            $local_search_gos = search_go_with_ids($dbh, $search_go, $uni_go_id, $species_id, $local_search_gos);

        }


        if ($prot->[1] eq 'Cel') {

            if ($prot->[0] ne $search_id) {

                my $tmp_id = get_worm_gid($dbh, $search_id);

                $search_id = $prot->[0] . ' <br>(' . $search_id;

                if ($tmp_id) {

                    $search_id .= '; <br />' . $tmp_id . ')';

                } else {

                    $search_id .= ')';

                }

            }

        } elsif ($prot->[0] ne $search_id) {

            $search_id = $prot->[0] . ' <br>(' . $search_id . ')';

        } elsif ($prot->[1] eq 'Eco') {

            my $tmp_id = get_eco_id($dbh, $search_id);

            if ($tmp_id) {

                $search_id = $search_id . ' <br>(' . $tmp_id . ')';

            }

        } elsif ($gene_name) {

            $search_id = $prot->[0] . ' <br>(' . $gene_name . ')';

        }

        my $link =
            a({-href   => $href,
               -style  => $gStyle,
               -target => $gBlank,
               -title  => $title},
              $search_id);

        if ($prot->[1] eq 'Ncr' or
            $prot->[1] eq 'Osa') {

            $link = $search_id;

        }

        my $href2 = "http://www.expasy.org/cgi-bin/niceprot.pl?$uni_id";
        my $href3 = "http://orthomcl.cbil.upenn.edu/cgi-bin/OrthoMclWeb.cgi?rm=sequence&accession=$prot->[2]";

        my $tax_id = $species_tax_rev{$species_id};

        my $tax_href = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$tax_id";

        push(@ortho, td({-align   => 'center',
                         -bgcolor => $species_colour{$species_id} },
                        [a({-href   => $tax_href,
                            -style  => $gStyle,
                            -target => $gBlank,
                            -title  => 'NCBI Taxonomy'},
                           $species_name{$species_id} . ' (' . $species_3let{$species_id} . ')'),
                         a({-href   => $href3,
                            -style  => $gStyle,
                            -target => $gBlank,
                            -title  => 'OrthoMCL Sequence'},
                           $prot->[2]),
                         $link,
                         a({-href   => $href2,
                            -style  => $gStyle,
                            -target => $gBlank,
                            -title  => 'UniProt'},
                           $uni_id)]) );

    }

    undef my @ortho_values;

    foreach my $key (@orthomcl_keys) {

        #print "[$key]\n";

        if (exists $orthomcl_count_hash{$key}) {

            push @ortho_values, $orthomcl_count_hash{$key};

        } else {

            push @ortho_values, 0;

        }

    }

    print "<p>", a({-name  => 'orthomcl',
                    -style => $gNone},
                   h4('OrthoMCL results: ') ), "</p>", "<b>Selected databases only</b><br />";

    my $graph = draw_orthomcl_graph(\@orthomcl_keys, \@ortho_values);
    #my $graph = '';

    my $link_cluster = $orthomcl_cluster + 1;

    my $href1 = "http://orthomcl.cbil.upenn.edu/cgi-bin/OrthoMclWeb.cgi?rm=sequenceList&groupid=$link_cluster";

    undef my @orthomclheadings;

    push(@orthomclheadings, td({-align => 'center',
                                -style => 'font-style: italic'},
                               ['OrthoMCL cluster',
                                'Phylogenetic pattern']) );

    push(@orthomclheadings, td({-align   => 'center'},
                               [a({-href   => $href1,
                                   -style  => $gStyle,
                                   -target => $gBlank,
                                   -title  => 'OrthoMCL cluster page'},
                                  'OG1_' . $orthomcl_cluster),
                                "<img src = $TMPURI/$graph />"]) );

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@orthomclheadings) ), "</p>";

    undef my @orthomclheadings2;

    push(@orthomclheadings2, td({-align => 'center',
                                 -style => 'font-style: italic'},
                                ['Species',
                                 'OrthoMCL <br />sequence',
                                 'Model organism <br />protein page',
                                 'UniProt link']) );

    undef my @orthomcl;

    push @orthomcl, @orthomclheadings2;

    push @orthomcl, @ortho;

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@orthomcl) ), "</p>";

    if ($go_final eq 'No' and $go_term eq 'Yes') {

        print_go_table($dbh, 'OrthoMCL', $local_search_gos);

    }

    print_back_to_top();

}


###############################################################################

sub do_vals {

    my ($dbh, $new_id, $species, $go_term, $go_final, $gene_info) = @_;

    my @curated_results = get_val_results($dbh, $new_id);

    undef my @val_rows;
    undef my @val;

    push(@val_rows,
         td({-align => 'center',
             -style => 'font-style: italic'},
            ['S. pombe <br />systematic ID',
             'S. cerevisiae <br />systematic ID']) );

    my $sp_go_ids = undef;
    my $sc_go_ids = undef;

    undef my $local_search_gos;

    foreach my $prot (@curated_results) {

        my $sp_id = make_gene_id($prot->[0]);

        my $sp_uni_id = get_pombe_uni_id($dbh, $sp_id);

        $sp_uni_id = ''
            if not defined $sp_uni_id;

        my $sc_id = uc(get_budding_id($dbh, $prot->[1]) );

        $sc_id = uc $prot->[1]
            if not defined $sc_id or not $sc_id;

        if ($go_term eq 'Yes') {

            my $species_id = '60';

            my $search_go = $sp_id;
            my $uni_id = $sp_uni_id;

            my $uni_go_id = $uni_id;

            $uni_go_id =~ s/\-\d+$//;

            $local_search_gos = search_go_with_ids($dbh, $search_go, $uni_go_id, $species_id, $local_search_gos);

            $species_id = '50';

            $search_go = $sc_id;
            $uni_id = '';

            $uni_go_id = $uni_id;

            $uni_go_id =~ s/\-\d+$//;

            $local_search_gos = search_go_with_ids($dbh, $search_go, $uni_go_id, $species_id, $local_search_gos);

        }

        my $href  = "http://old.genedb.org/genedb/Search?organism=S.+pombe&name=$sp_id";
        my $title = 'GeneDB';

        if ($sp_uni_id) {

            $sp_id = $sp_id . ' <br>(' . $sp_uni_id . ')';

        }

        my $sp_link = a({-href   => $href,
                         -style  => $gStyle,
                         -target => $gBlank,
                         -title  => $title},
                        $sp_id);

        $prot->[1] = uc $prot->[1];

        $href  = "http://db.yeastgenome.org/cgi-bin/locus.pl?locus=$sc_id";
        $title = 'SGD';

        if (uc($prot->[1]) ne $sc_id) {

            $sc_id = $prot->[1] . ' <br>(' . $sc_id . ')';

        }

        my $sc_link = a({-href   => $href,
                         -style  => $gStyle,
                         -target => $gBlank,
                         -title  => $title},
                        $sc_id);

        push(@val_rows, td({-align   => 'center',
                            -bgcolor => "#ccddff"},
                           [$sp_link,
                            $sc_link]) );

    }

    print "<p>", a({-name  => 'curated',
                    -style => $gNone},
                   h4('Curated yeast ortholog results: ') ), "</p>";

    print ' ' x 2048;

    print "<p>", table({-class       => 'violet3',
                        -cellpadding => '2'},
                       Tr(\@val_rows) ), "</p>";

    if ($go_final eq 'No' and $go_term eq 'Yes') {

        print_go_table($dbh, 'curated homolog', $local_search_gos);

    }

    print_back_to_top();

}


###############################################################################

sub print_help_bar {

    print table({-width       => '100%',
                 -cellpadding => '2'},
                Tr({-align  => 'center',
                    -valign => 'top',
                    -class  => 'violet3'},
                   [td(['', '<a href="/YOGY/index.shtml" target=$gBlank ' .
                        "style='$gStyle'>YOGY Home</a>",
                        '', '<a href="/YOGY/help.shtml" target=$gBlank ' .
                        "style='$gStyle'>YOGY Help</a>", '']) ])
               );

}


###############################################################################

sub print_web_bar {

    print table({-width       => '100%',
                 -cellpadding => '2'},
                Tr({-align  => 'center',
                    -valign => 'top',
                    -class  => 'violet3'},
                   [td(['', '<a href="mailto:s.khadayate@ucl.ac.uk" style="' . $gStyle .
                        '">s.khadayate@ucl.ac.uk</a>', '']) ])
               );

}


###############################################################################

sub print_form {

    print start_form();

    print p('<b>Search for gene by ID or name</b>: ',
            textfield('gene', '', 30, 100) );

    print p('<b>Query species</b>: ',
            scrolling_list(-name    => 'species',
                           -values  => ['A._thaliana',
                                        'C._elegans',
                                        'D._discoideum',
                                        'D._melanogaster',
                                        'E._coli',
                                        'H._sapiens',
                                        'M._musculus',
                                        'P._falciparum',
                                        'R._norvegicus',
                                        'S._cerevisiae',
                                        'S._pombe'],
                           -labels  => {'A._thaliana'     => 'A. thaliana',
                                        'C._elegans'      => 'C. elegans',
                                        'D._discoideum'   => 'D. discoideum',
                                        'D._melanogaster' => 'D. melanogaster',
                                        'E._coli'         => 'E. coli',
                                        'H._sapiens'      => 'H. sapiens',
                                        'M._musculus'     => 'M. musculus',
                                        'P._falciparum'   => 'P. falciparum',
                                        'R._norvegicus'   => 'R. norvegicus',
                                        'S._cerevisiae'   => 'S. cerevisiae',
                                        'S._pombe'        => 'S. pombe'},
                           -size    => 1,
                           -default => 'S._pombe') );

    print p('<b>Include wild-cards</b>: &nbsp;&nbsp;',
            radio_group(-name    => 'wild',
                        -values  => ['Yes', 'No'],
                        -default => 'No') );

    print p('<b>Search for GO info</b>: &nbsp;',
            radio_group(-name    => 'go_term',
                        -values  => ['Yes', 'No'],
                        -default => 'No') );

    print p('<b>GO info in one table</b>: ',
            radio_group(-name    => 'go_final',
                        -values  => ['Yes', 'No'],
                        -default => 'Yes') );

    print p(submit('Find orthologs'), defaults('Reset') );

    print ' ' x 2048;

    print end_form();

}


###############################################################################

sub print_back_to_top {

    print a({-href  => "#gene",
             -style => $gNone},
            'Back to the top');

    print hr({-align => 'left',
              -size  => '2',
              -width => '80%'});

}


###############################################################################

sub get_gene_info {

    my ($dbh, $gene_name, $wild_card, $species) = @_;

    my $gene_info = undef;

    if ($species eq 'S._pombe') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_pombe($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_pombe_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'S._cerevisiae') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_budding($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_budding_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'C._elegans') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_worm($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_worm_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'A._thaliana') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_arab($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_arab_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'D._melanogaster') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_fly($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_fly_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'H._sapiens') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_human($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_human_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'M._musculus') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_mouse($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_mouse_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'R._norvegicus') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_rat($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_rat_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'P._falciparum') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_plasmo($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_plasmo_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'D._discoideum') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_dicty($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_dicty_wild($dbh, $gene_name);

        }

    } elsif ($species eq 'E._coli') {

        if ($wild_card eq 'No') {

            $gene_info = get_gene_info_eco($dbh, $gene_name);

        } elsif ($wild_card eq 'Yes') {

            $gene_info = get_gene_info_eco_wild($dbh, $gene_name);

        }

    }

    return ($gene_info);

}


###############################################################################

sub get_gene_info_pombe {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT *
                    FROM   pombe_gene
                    WHERE  GeneDB_systematic_id = ?
                    OR     GeneDB_primary       = ?
                    OR     PombePD_Systematic   = ?);

    my $sth_querya = $dbh->prepare($string);

    $sth_querya->execute($gene_name, $gene_name, $gene_name);

    $gene_info = $sth_querya->fetchrow_arrayref();

    if (not defined $gene_info) {

        my $string = qq(SELECT protein_id
                        FROM   pombe_synonyms
                        WHERE  synonym = ?);

        my $sth_queryb = $dbh->prepare($string);

        $sth_queryb->execute($gene_name);

        $gene_info = $sth_queryb->fetchrow_arrayref();

        if (defined $gene_info) {

            my $string = qq(SELECT *
                            FROM   pombe_gene
                            WHERE  GeneDB_systematic_id = ?);

            my $sth_queryc = $dbh->prepare($string);

            $sth_queryc->execute($gene_info->[0]);

            $gene_info = $sth_queryc->fetchrow_arrayref();

        }

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_pombe_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT *
                    FROM   pombe_gene
                    WHERE  GeneDB_systematic_id LIKE ?
                    OR     GeneDB_primary       LIKE ?
                    OR     PombePD_Systematic   LIKE ?
                    LIMIT  0, 100);

    my $sth_querya = $dbh->prepare($string);

    $sth_querya->execute('%' . $gene_name . '%',
                         '%' . $gene_name . '%',
                         '%' . $gene_name . '%');

    while (my @row = $sth_querya->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    if (not defined $gene_info) {

        my $string = qq(SELECT protein_id
                        FROM   pombe_synonyms
                        WHERE  synonym LIKE ?);

        my $sth_queryb = $dbh->prepare($string);

        $sth_queryb->execute('%' . $gene_name . '%');

        while (my @row = $sth_queryb->fetchrow_array() ) {

            push @{$gene_info}, \@row;

        }

        if (defined $gene_info) {

            foreach my $qu (@{$gene_info}) {

                my $string = qq(SELECT *
                                FROM   pombe_gene
                                WHERE  GeneDB_systematic_id = ?
                                LIMIT  0, 100);

                my $sth_queryc = $dbh->prepare($string);

                $sth_queryc->execute($qu);

                my @row = $sth_queryc->fetchrow_array();

                push @{$gene_info}, \@row;

            }

        }

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_budding {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT SGDID,
                           SGD_symbol,
                           SGD_descrip,
                           SGD_sys_name
                    FROM   budding_gene
                    WHERE  SGD_symbol   = ?
                    OR     SGD_sys_name = ?
                    OR     SGDID        = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name, $gene_name, $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}

###############################################################################

sub get_gene_info_budding_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT SGDID,
                           SGD_symbol,
                           SGD_descrip,
                           SGD_sys_name
                    FROM   budding_gene
                    WHERE  SGD_symbol   LIKE ?
                    OR     SGD_sys_name LIKE ?
                    OR     SGDID        LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_worm {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT WP.WP_id,
                           WG.WB_name,
                           WP.CE_descrip,
                           WG.WB_id,
                           WG.WB_descrip
                    FROM   worm_gene WG,
                           worm_pep  WP
                    WHERE  WG.CE_id   = WP.CE_id
                    AND   (WP.WP_id   = ?
                    OR     WG.WB_name = ?
                    OR     WG.WB_id   = ?
                    OR     WG.CE_id   = ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('WP:' . $gene_name, $gene_name, $gene_name, $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    if (not $gene_info->[0]) {

        my $string = qq(SELECT WP_id,
                               CE_id,
                               CE_descrip
                        FROM   worm_pep
                        WHERE  WP_id   = ?
                        OR     CE_id   = ?);

        my $sth_query = $dbh->prepare($string);

        $sth_query->execute('WP:' . $gene_name, $gene_name);

        $gene_info = $sth_query->fetchrow_arrayref();

    }

    $gene_info->[0] =~ s/^WP://;

    return $gene_info;

}


###############################################################################

sub get_gene_info_worm_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT WP.WP_id,
                           WG.WB_name,
                           WP.CE_descrip,
                           WG.WB_id,
                           WG.WB_descrip
                    FROM   worm_gene WG,
                           worm_pep  WP
                    WHERE  WG.CE_id   = WP.CE_id
                    AND   (WP.WP_id   LIKE ?
                    OR     WG.WB_name LIKE ?
                    OR     WG.WB_id   LIKE ?
                    OR     WG.CE_id   LIKE ?)
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        $row[0] =~ s/^WP://;

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_fly {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT DM_id,
                           FB_name,
                           FB_descrip,
                           FB_id
                    FROM   fly_gene
                    WHERE  DM_id   = ?
                    OR     FB_name = ?
                    OR     FB_id   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name, $gene_name, $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}


###############################################################################

sub get_gene_info_fly_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT DM_id,
                           FB_name,
                           FB_descrip,
                           FB_id
                    FROM   fly_gene
                    WHERE  DM_id   LIKE ?
                    OR     FB_name LIKE ?
                    OR     FB_id   LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_arab {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT TAIR_id,
                           prot_acc,
                           prot_gi
                    FROM   arab_gene
                    WHERE  TAIR_id  LIKE ?
                    OR     prot_acc LIKE ?
                    OR     prot_gi  = ?);


    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name . '%', $gene_name . '%', $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}

###############################################################################

sub get_gene_info_arab_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT TAIR_id,
                           prot_acc,
                           prot_gi
                    FROM   arab_gene
                    WHERE  TAIR_id  LIKE ?
                    OR     prot_acc LIKE ?
                    OR     prot_gi  LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_human {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT human_id,
                           human_id
                    FROM   human_gene
                    WHERE  human_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}


###############################################################################

sub get_gene_info_human_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT human_id,
                           human_id
                    FROM   human_gene
                    WHERE  human_id LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_mouse {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT MGI_id,
                           MGI_name,
                           MGI_descrip,
                           uni_id
                    FROM   mouse_gene
                    WHERE  MGI_id   = ?
                    OR     MGI_name = ?
                    OR     uni_id   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('MGI:' . $gene_name, $gene_name, $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    $gene_info->[0] =~ s/^MGI://;

    return $gene_info;

}


###############################################################################

sub get_gene_info_mouse_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT MGI_id,
                           MGI_name,
                           MGI_descrip,
                           uni_id
                    FROM   mouse_gene
                    WHERE  MGI_id   LIKE ?
                    OR     MGI_name LIKE ?
                    OR     uni_id   LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        $row[0] =~ s/^MGI://;

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_rat {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT RGD_id,
                           RGD_name,
                           RGD_descrip,
                           uni_id
                    FROM   rat_gene
                    WHERE  RGD_id   = ?
                    OR     RGD_name = ?
                    OR     uni_id   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name, $gene_name, $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}


###############################################################################

sub get_gene_info_rat_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT RGD_id,
                           RGD_name,
                           RGD_descrip,
                           uni_id
                    FROM   rat_gene
                    WHERE  RGD_id   LIKE ?
                    OR     RGD_name LIKE ?
                    OR     uni_id   LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_plasmo {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT plasmo_id,
                           plasmo_id,
                           plasmo_descrip
                    FROM   plasmo_gene
                    WHERE  plasmo_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}


###############################################################################

sub get_gene_info_plasmo_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT plasmo_id,
                           plasmo_id,
                           plasmo_descrip
                    FROM   plasmo_gene
                    WHERE  plasmo_id LIKE ?
                    LIMIT  0, 100);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_dicty {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT dicty_id,
                           dicty_name,
                           dicty_descrip,
                           dicty_syn
                    FROM   dicty_gene
                    WHERE  dicty_id   = ?
                    OR     dicty_name = ?
                    OR     dicty_syn  LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name, $gene_name, '%' . $gene_name . '%');

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}


###############################################################################

sub get_gene_info_dicty_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT dicty_id,
                           dicty_name,
                           dicty_descrip,
                           dicty_syn
                    FROM   dicty_gene
                    WHERE  dicty_id   LIKE ?
                    OR     dicty_name LIKE ?
                    OR     dicty_syn  LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_gene_info_eco {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT eco_id,
                           eco_name,
                           eco_descrip,
                           prot_gi
                    FROM   eco_gene
                    WHERE  eco_id   = ?
                    OR     eco_name = ?
                    OR     uni_id   = ?
                    OR     gene_id  = ?
                    OR     ref_gi   = ?
                    OR     ref_acc  = ?
                    OR     prot_gi  = ?
                    OR     prot_acc = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($gene_name, $gene_name, $gene_name, $gene_name,
                        $gene_name, $gene_name, $gene_name, $gene_name);

    $gene_info = $sth_query->fetchrow_arrayref();

    return $gene_info;

}


###############################################################################

sub get_gene_info_eco_wild {

    my ($dbh, $gene_name) = @_;

    my $gene_info = undef;

    my $string = qq(SELECT eco_id,
                           eco_name,
                           eco_descrip,
                           prot_gi
                    FROM   eco_gene
                    WHERE  eco_id   LIKE ?
                    OR     eco_name LIKE ?
                    OR     uni_id   LIKE ?
                    OR     gene_id  LIKE ?
                    OR     ref_gi   LIKE ?
                    OR     ref_acc  LIKE ?
                    OR     prot_gi  LIKE ?
                    OR     prot_acc LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%',
                        '%' . $gene_name . '%');

    while (my @row = $sth_query->fetchrow_array() ) {

        #print "[@row]\n";

        push @{$gene_info}, \@row;

    }

    return $gene_info;

}


###############################################################################

sub get_synonyms_pombe {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT synonyms.synonym
                    FROM   pombe_synonyms
                    WHERE  protein_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    undef my @synonyms;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @synonyms, @row;

    }

    return @synonyms;
}


###############################################################################

sub db_data_check {

    my ($dbh, $db_id, $primary, $alt_id, $species) = @_;

    #print "[$db_id] [$primary]\n";

    my $species_id = $species_id{$species};

    my $tax_id = $species_tax_rev{$species_id};

    undef my @data_check;

    my $kogs_string = qq(SELECT gi_number
                         FROM   kog_member
                         WHERE  species_id = ?
                         AND   (protein_id = ?
                         OR     gi_number  = ?) );

    my $sth_kogs = $dbh->prepare($kogs_string);

    my $search_id = $db_id;

    if ($search_id =~ /^ENS/) {

        $search_id = $primary;

    }

    if ($species eq 'S._cerevisiae') {

        $search_id = $alt_id
            if defined $alt_id and $alt_id;

    } elsif ($species eq 'A._thaliana') {

        $search_id =~ s/\.\d+$//;

    } elsif ($species eq 'D._melanogaster' or $species eq 'H._sapiens') {

        my $tmp_id = get_gi_from_id($dbh, $search_id, $tax_id);

        if (defined $tmp_id and $tmp_id) {

            $search_id = $tmp_id;

        } else {

            my $tmp_id = get_gi_from_id($dbh, $primary, $tax_id);

            if (defined $tmp_id and $tmp_id) {

                $search_id = $tmp_id;

            } else {

                $tmp_id = get_gi_from_id($dbh, $alt_id, $tax_id);

                $search_id = $tmp_id
                    if defined $tmp_id and $tmp_id;

            }

        }

    }

    #print "[$search_id]\n";

    $sth_kogs->execute($species_id, $search_id, $search_id);

    my @kogs = $sth_kogs->fetchrow_array();

    #print "KOGS: [$search_id] [$species_id] [@kogs]\n";

    if (@kogs) {

        push @data_check, 'Y';

        $gi_query = $kogs[0];

    } else {

        push @data_check, 'N';

    }


    my $inparanoid_string = qq(SELECT *
                               FROM   inparanoid_member
                               WHERE  uniprot_id = ?);

    $search_id = $db_id;

    if ($species eq 'C._elegans') {

        $search_id = $alt_id;

    } elsif ($species eq 'D._melanogaster') {

        $inparanoid_string = qq(SELECT *
                                FROM   inparanoid_member
                                WHERE  uniprot_id LIKE ?);

        $search_id = $search_id . '-%';

    } elsif ($species eq 'A._thaliana') {

        $search_id = $primary;

        $search_id =~ s/\.\d+$//;

    } elsif ($species eq 'H._sapiens') {

        $search_id = $ens_query;

    } elsif ($species eq 'E._coli') {

        my $tmp_id = get_eco_ref_acc($dbh, $db_id);

        $search_id = $tmp_id, $search_id =~ s/\.\d+$//
            if defined $tmp_id and $tmp_id;

    }

    my $sth_inparanoid = $dbh->prepare($inparanoid_string);

    $sth_inparanoid->execute($search_id);

    my @inpara_keys_excl = qw(ensAM ensCE ensDM ensTN modCB modDP);

 INP:
    while (my @inpara = $sth_inparanoid->fetchrow_array() ) {

        foreach my $excl (@inpara_keys_excl) {

            if ($inpara[3] =~ /$excl/) {

                next INP;

            }

        }

        #print "INP: [$search_id] [@inpara]\n";

        if (@inpara) {

            push @data_check, 'Y';

        } else {

            push @data_check, 'N';

        }

        last INP;

    }

    #print "INP: [$search_id]\n";

    $data_check[1] = 'N'
        if scalar @data_check == 1;


    my $homologene_string = qq(SELECT HID
                               FROM   homologene
                               WHERE  tax_id    = ?
                               AND    gi_number = ?);

    my $sth_homologene = $dbh->prepare($homologene_string);

    $sth_homologene->execute($tax_id, $gi_query);

    my $homolo = $sth_homologene->fetchrow_arrayref();

    #print "HOM [$gi_query]\n";

    if ($homolo and defined $homolo) {

        push @data_check, 'Y';

    } else {

        my $homologene_string = qq(SELECT HID
                                   FROM   homologene
                                   WHERE  tax_id            = ?
                                   AND   (gene_symbol       = ?
                                   OR     protein_accession = ?) );

        my $sth_homologene = $dbh->prepare($homologene_string);

        my $search_id = $db_id;

        if ($species eq 'S._cerevisiae') {

            $search_id = $alt_id;

        } elsif ($species eq 'A._thaliana') {

            $search_id =~ s/\.\d+$//;

        }

        #print "HOM [$search_id]\n";

        $sth_homologene->execute($tax_id, $search_id, $search_id);

        my $homolo = $sth_homologene->fetchrow_arrayref();

        if ($homolo and defined $homolo) {

            push @data_check, 'Y';

        } else {

            my $homologene_string = qq(SELECT HID
                                       FROM   homologene
                                       WHERE  tax_id            = ?
                                       AND   (gene_symbol       = ?
                                       OR     protein_accession = ?) );

            my $sth_homologene = $dbh->prepare($homologene_string);

            if ($species eq 'A._thaliana') {

                $primary =~ s/\.\d+$//;

            }

            #print "HOM [$primary] [$tax_id]\n";

            $sth_homologene->execute($tax_id, $primary, $primary);

            my $homolo = $sth_homologene->fetchrow_arrayref();

            if ($homolo and defined $homolo) {

                push @data_check, 'Y';

            } else {

                push @data_check, 'N';

            }

        }

    }


    my $orthomcl_string = qq(SELECT ome.cluster_id
                             FROM   orthomcl_member ome,
                                    orthomcl_lookup olo
                             WHERE  ome.ortho_id = olo.ortho_id
                             AND    ome.org_tlc  = ?
                             AND    olo.db_id1   = ?);

    my $search_id = $db_id;

    if ($species eq 'S._cerevisiae') {

        $search_id = $alt_id
            if defined $alt_id and $alt_id;

    } elsif ($species eq 'E._coli') {

        my $tmp_id = get_eco_ref_gi($dbh, $db_id);

        $search_id = $tmp_id
            if defined $tmp_id and $tmp_id;

    } elsif ($species eq 'H._sapiens' or
             $species eq 'M._musculus' or
             $species eq 'R._norvegicus') {

        $search_id = $ens_query;

        $search_id = 'NO_ENS_ID'
            if not $search_id;

    } elsif ($species eq 'D._melanogaster') {

        $orthomcl_string = qq(SELECT ome.cluster_id
                              FROM   orthomcl_member ome,
                                     orthomcl_lookup olo
                              WHERE  ome.ortho_id = olo.ortho_id
                              AND    ome.org_tlc  = ?
                              AND    olo.db_id1   LIKE ?);

        $search_id = $search_id . '-%';

    } elsif ($species eq 'C._elegans') {

        my $tmp_id = get_worm_wid($dbh, $search_id);

        if (defined $tmp_id and $tmp_id) {

            $search_id = $tmp_id;

        } else {

            my $tmp_id = get_worm_wid2($dbh, $search_id);

            $search_id = $tmp_id
                if defined $tmp_id and $tmp_id;

        }

    }

    my $sth_omcl = $dbh->prepare($orthomcl_string);

    $sth_omcl->execute($species_3let{$species_id}, $search_id);

    my @orthomcl = $sth_omcl->fetchrow_array();

    #print "OrthoMCL: [$species_3let{$species_id}] [$search_id] [@orthomcl]\n";

    if (@orthomcl) {

        push @data_check, 'Y';

    } else {

        push @data_check, 'N';

    }


    if ($species eq 'S._pombe') {

        my $vals_string = qq(SELECT *
                             FROM   vals_orthologs
                             WHERE  pombe_id  = ?
                             AND    yeast_id != 'none');

        my $sth_vals = $dbh->prepare($vals_string);

        $sth_vals->execute($db_id);

        my @vals = $sth_vals->fetchrow_array();

        if (@vals) {

            push @data_check, 'Y';

        } else {

            push @data_check, 'N';

        }

    } elsif ($species eq 'S._cerevisiae') {

        my $vals_string = qq(SELECT *
                             FROM   vals_orthologs
                             WHERE  pombe_id != 'none'
                             AND    yeast_id  = ?);

        my $sth_vals = $dbh->prepare($vals_string);

        $sth_vals->execute($alt_id);

        my @vals = $sth_vals->fetchrow_array();

        if (@vals) {

            push @data_check, 'Y';

        } else {

            push @data_check, 'N';

        }

    }

    return @data_check;

}


###############################################################################

sub get_kogs_results {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT kog_id
                    FROM   kog_member
                    WHERE  species_id = ?
                    AND   (protein_id = ?
                    OR     gi_number  = ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    #print "[$db_id] [@row]\n";

    my $string2 = qq(SELECT *
                     FROM   kogs
                     WHERE  kog_id = ?);

    my $sth_query2 = $dbh->prepare($string2);

    $sth_query2->execute($row[0]);

    my @row2 = $sth_query2->fetchrow_array();

    return @row2;

}


###############################################################################

sub get_prot_results {

    my ($dbh, $kog_id) = @_;

    my $string = qq(SELECT *
                    FROM   kog_member
                    WHERE  kog_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($kog_id);

    undef my @prot_ids;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @prot_ids, \@row;

    }

    return @prot_ids;

}


###############################################################################

sub get_func_results {

    my ($dbh, $kog_code) = @_;

    my $string = qq(SELECT *
                    FROM   function
                    WHERE  process_key = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($kog_code);

    my @row = $sth_query->fetchrow_array();

    return @row;

}


###############################################################################

sub draw_kogs_graph {

    my ($xaxis_ref, $yaxis_ref) = @_;

    my $my_graph = GD::Graph::bars->new(260, 120);

    my @data = ($xaxis_ref, $yaxis_ref);

    my $max = -1;

    foreach my $y (@{$yaxis_ref}) {

        $max = $y
            if $y > $max;

    }

    my $y_max_value   = $max;
    my $y_label_skip  = 'auto';
    my $y_tick_number = 'auto';

    if ($max == 1) {
        $y_max_value   = $max + 1;
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 2) {
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 3) {
        $y_label_skip  = 1;
        $y_tick_number = 3;
    }

    if ($y_max_value > 6) {
        $y_max_value = ( (int($y_max_value/5) + 1)*5);
    } elsif ($y_max_value > 20) {
        $y_max_value = ( (int($y_max_value/10) + 1)*10);
    }

    $my_graph->set(y_min_value   => 0,
                   y_max_value   => $y_max_value,
                   y_label       => 'No. of orthologs',
                   y_label_skip  => $y_label_skip,
                   y_tick_number => $y_tick_number,
                   x_labels_vertical => 1,
                   cycle_clrs    => 1,
                   dclrs => ['#ccffcc',
                             '#ffffcc',
                             '#ffddcc',
                             '#ffccff',
                             '#ccddff',
                             '#ccccff',
                             '#cceecc']
                  ) or die $my_graph->error;

    $my_graph->set_x_axis_font(GD::gdSmallFont);
    $my_graph->set_y_axis_font(GD::gdSmallFont);

    my $gd = $my_graph->plot(\@data)
        or die $my_graph ->error;

    my $format = $my_graph->export_format;

    my $rand = int(rand(100000) );

    my ($fpath) = $TMPDIR =~ m|([a-zA-Z0-9_\-/\.]+)|;

    my $id = Website::Utilities::IdGenerator->get_unique_id();

    $fpath .= "/$id.$format";

    open GRAPH, ">$fpath"
        or die qq($fpath: $!);

    binmode GRAPH;

    print GRAPH $my_graph->plot(\@data)->$format;

    close GRAPH;

    return "$id.$format";

}


###############################################################################

sub phy_info {

    my ($species_count) = shift;

    undef my @values;
    undef my $phystring;

    my $phylink = 0;

    my $pow2 = 1;

    foreach my $species_id (@kogs_species_id) {

        if (exists $species_count->{$species_id}) {

            $phystring = $phystring . $species_1let{$species_id};
            $phylink = ($phylink + $pow2);

            push @values, $species_count->{$species_id};

        } else {

            $phystring = $phystring . '-';

            push @values, 0;

        }

        $pow2 *= 2;

    }

    return ($phystring, $phylink, @values);

}


###############################################################################

sub get_inparanoid_results {

    my ($dbh, $db_id, $species) = @_;

    my $search_id = $db_id;

    my $string = qq(SELECT   cluster_nr,
                             organism_pair
                    FROM     inparanoid_member
                    WHERE    uniprot_id = ?
                    ORDER BY organism_pair);

    if ($species eq 'D._melanogaster') {

        $string = qq(SELECT   cluster_nr,
                              organism_pair
                     FROM     inparanoid_member
                     WHERE    uniprot_id LIKE ?
                     ORDER BY organism_pair);

        $search_id = $search_id . '-%';

    }

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($search_id);

    undef my @cluster_numbers;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @cluster_numbers, \@row;

    }

    undef my @query;

    if ($species eq 'S._pombe') {

        @query = ('query', '-', 'modSP', '-', '-', $db_id);

    } elsif ($species eq 'S._cerevisiae') {

        @query = ('query', '-', 'modSC', '-', '-', uc($db_id) );

    } elsif ($species eq 'C._elegans') {

        @query = ('query', '-', 'modCE', '-', '-', $db_id);

    } elsif ($species eq 'A._thaliana') {

        @query = ('query', '-', 'ncbAT', '-', '-', $db_id);

    } elsif ($species eq 'D._melanogaster') {

        @query = ('query', '-', 'modDM', '-', '-', $db_id);

    } elsif ($species eq 'M._musculus') {

        @query = ('query', '-', 'modMM', '-', '-', $db_id);

    } elsif ($species eq 'R._norvegicus') {

        @query = ('query', '-', 'modRR', '-', '-', $db_id);

    } elsif ($species eq 'P._falciparum') {

        @query = ('query', '-', 'sanPF', '-', '-', $db_id);

    } elsif ($species eq 'H._sapiens') {

        @query = ('query', '-', 'ensHS', '-', '-', $db_id);

    } elsif ($species eq 'D._discoideum') {

        @query = ('query', '-', 'modDD', '-', '-', $db_id);

    } elsif ($species eq 'E._coli') {

        @query = ('query', '-', 'ncbEC', '-', '-', $db_id);

    }

    undef my @inparanoids;

    push @inparanoids, \@query;

    foreach my $prot (@cluster_numbers) {

        my $string = qq(SELECT   *
                        FROM     inparanoid_member
                        WHERE    cluster_nr    = ?
                        AND      organism_pair = ?
                        AND      uniprot_id   != ?
                        ORDER BY organism_pair,
                                 inparalog_score DESC);

        if ($species eq 'D._melanogaster') {

            $string = qq(SELECT   *
                         FROM     inparanoid_member
                         WHERE    cluster_nr    = ?
                         AND      organism_pair = ?
                         AND      uniprot_id    NOT LIKE ?
                         ORDER BY organism_pair,
                                  inparalog_score DESC);

        }

        my $sth_query = $dbh->prepare($string);

        $sth_query->execute($prot->[0], $prot->[1], $search_id);

        while (my @row = $sth_query->fetchrow_array() ) {

            push @inparanoids, \@row;

        }

    }

    #print "[IN INP: [$db_id]\n";

    return @inparanoids;

}


###############################################################################

sub draw_inparanoid_graph {

    my ($xaxis_ref, $yaxis_ref) = @_;

    my $my_graph = GD::Graph::bars->new(540, 150);

    my @data = ($xaxis_ref, $yaxis_ref);

    my $max = -1;

    foreach my $y (@{$yaxis_ref}) {

        $max = $y
            if $y > $max;

    }

    my $y_max_value   = $max;
    my $y_label_skip  = 'auto';
    my $y_tick_number = 'auto';

    if ($max == 1) {
        $y_max_value   = $max + 1;
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 2) {
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 3) {
        $y_label_skip  = 1;
        $y_tick_number = 3;
    }

    if ($y_max_value > 6) {
        $y_max_value = ( (int($y_max_value/5) + 1)*5);
    } elsif ($y_max_value > 20) {
        $y_max_value = ( (int($y_max_value/10) + 1)*10);
    }

    $my_graph->set(y_min_value   => 0,
                   y_max_value   => $y_max_value,
                   y_label       => 'No. of orthologs',
                   y_label_skip  => $y_label_skip,
                   y_tick_number => $y_tick_number,
                   x_labels_vertical => 1,
                   cycle_clrs    => 1,
                   dclrs => ["#ffdfdf",
                             "#efdcaa",
                             "#bbebff",
                             "#8ceffd",
                             "#ffdfff",
                             "#ffccff",
                             "#efe7cf",
                             "#eedcc8",
                             "#f0dcd5",
                             "#ffffcc",
                             "#d2dbd5",
                             "#ffddcc",
                             "#efe7cf",
                             "#d1ffb3",
                             "#f0dcd5",
                             "#ccddff",
                             "#ccccff",
                             "#ccffcc",
                             "#eeeea2",
                             "#c9decb"]
                  ) or die $my_graph->error;

    $my_graph->set_x_axis_font(GD::gdSmallFont);
    $my_graph->set_y_axis_font(GD::gdSmallFont);

    my $gd = $my_graph->plot(\@data)
        or die $my_graph ->error;

    my $format = $my_graph->export_format;

    my $rand = int(rand(100000) );

    my ($fpath) = $TMPDIR =~ m|([a-zA-Z0-9_\-/\.]+)|;

    my $id = Website::Utilities::IdGenerator->get_unique_id();

    $fpath .= "/$id.$format";

    open GRAPH, ">$fpath"
        or die qq($fpath: $!);

    binmode GRAPH;

    print GRAPH $my_graph->plot(\@data)->$format;

    close GRAPH;

    return "$id.$format";

}


###############################################################################

sub get_homologene_results {

    my ($dbh, $db_id, $primary, $species) = @_;

    my $tax_id = $species_tax_rev{$species_id{$species} };

    my $HID_id = '';

    my $string = qq(SELECT HID
                    FROM   homologene
                    WHERE  tax_id    = ?
                    AND    gi_number = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($tax_id, $gi_query);

    my $homolo = $sth_query->fetchrow_arrayref();

    if ($homolo and defined $homolo) {

        $HID_id = $homolo->[0];

    } else {

        my $string = qq(SELECT HID
                        FROM   homologene
                        WHERE  tax_id            = ?
                        AND   (gene_symbol       = ?
                        OR     protein_accession = ?) );

        my $sth_query = $dbh->prepare($string);

        if ($species eq 'A._thaliana') {

            $db_id =~ s/\.\d+$//;

        }

        $sth_query->execute($tax_id, $db_id, $db_id);

        my $homolo = $sth_query->fetchrow_arrayref();

        if ($homolo and defined $homolo) {

            $HID_id = $homolo->[0];

        } else {

            my $string = qq(SELECT HID
                            FROM   homologene
                            WHERE  tax_id            = ?
                            AND   (gene_symbol       = ?
                            OR     protein_accession = ?) );

            my $sth_query = $dbh->prepare($string);

            if ($species eq 'A._thaliana') {

                $primary =~ s/\.\d+$//;

            }

            $sth_query->execute($tax_id, $primary, $primary);

            my $homolo = $sth_query->fetchrow_arrayref();

            if ($homolo and defined $homolo) {

                $HID_id = $homolo->[0];

            } else {

                $HID_id = '';

            }

        }

    }

    if ($HID_id) {

        my $string = qq(SELECT *
                        FROM   homologene
                        WHERE  HID = ?);

        my $sth_query = $dbh->prepare($string);

        $sth_query->execute($HID_id);

        undef my @homologenes;

        while (my @row = $sth_query->fetchrow_array() ) {

            push @homologenes, \@row;

        }

        return @homologenes;

    }

}


###############################################################################

sub draw_homologene_graph {

    my ($xaxis_ref, $yaxis_ref) = @_;

    my $my_graph = GD::Graph::bars->new(500, 150);

    my @data = ($xaxis_ref, $yaxis_ref);

    my $max = -1;

    foreach my $y (@{$yaxis_ref}) {

        $max = $y
            if $y > $max;

    }

    my $y_max_value   = $max;
    my $y_label_skip  = 'auto';
    my $y_tick_number = 'auto';

    if ($max == 1) {
        $y_max_value   = $max + 1;
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 2) {
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 3) {
        $y_label_skip  = 1;
        $y_tick_number = 3;
    }

    if ($y_max_value > 6) {
        $y_max_value = ( (int($y_max_value/5) + 1)*5);
    } elsif ($y_max_value > 20) {
        $y_max_value = ( (int($y_max_value/10) + 1)*10);
    }

    $my_graph->set(y_min_value   => 0,
                   y_max_value   => $y_max_value,
                   y_label       => 'No. of orthologs',
                   y_label_skip  => $y_label_skip,
                   y_tick_number => $y_tick_number,
                   x_labels_vertical => 1,
                   cycle_clrs    => 1,
                   dclrs => ["#ffccff",
                             "#eedcc8",
                             "#efdcaa",
                             "#efe7cf",
                             "#f0dcd5",
                             "#ffdfff",
                             "#ffddcc",
                             "#ffdfdf",
                             "#ffffcc",
                             "#ccccff",
                             "#ccddff",
                             "#cceeff",
                             "#ffc848",
                             "#ffe920",
                             "#ffdd75",
                             "#ccffcc",
                             "#d1ffb3",
                             "#c9decb"]
                  ) or die $my_graph->error;

    $my_graph->set_x_axis_font(GD::gdSmallFont);
    $my_graph->set_y_axis_font(GD::gdSmallFont);

    my $gd = $my_graph->plot(\@data)
        or die $my_graph ->error;

    my $format = $my_graph->export_format;

    my $rand = int(rand(100000) );

    my ($fpath) = $TMPDIR =~ m|([a-zA-Z0-9_\-/\.]+)|;

    my $id = Website::Utilities::IdGenerator->get_unique_id();

    $fpath .= "/$id.$format";

    open GRAPH, ">$fpath"
        or die qq($fpath: $!);

    binmode GRAPH;

    print GRAPH $my_graph->plot(\@data)->$format;

    close GRAPH;

    return "$id.$format";

}


###############################################################################

sub get_orthomcl_cluster {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT ome.cluster_id
                    FROM   orthomcl_member ome,
                           orthomcl_lookup olo
                    WHERE  ome.ortho_id = olo.ortho_id
                    AND    ome.org_tlc  = ?
                    AND    olo.db_id1   = ?);

    if ($species_id eq 'D._melanogaster') {

        $string = qq(SELECT ome.cluster_id
                     FROM   orthomcl_member ome,
                            orthomcl_lookup olo
                     WHERE  ome.ortho_id = olo.ortho_id
                     AND    ome.org_tlc  = ?
                     AND    olo.db_id1   LIKE ?);

        $db_id = $db_id . '-%';

    }

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_3let{$species_id{$species_id} }, $db_id);

    my $ortho = $sth_query->fetchrow_arrayref();

    #print "[$db_id] [$species_id{$species_id}]";# [@{$ortho}]\n";

    return $ortho->[0];

}


###############################################################################

sub get_orthomcl_results {

    my ($dbh, $ortho_id) = @_;

    my $string = qq(SELECT   olo.db_id1,
                             ome.org_tlc,
                             olo.ortho_id
                    FROM     orthomcl_member ome,
                             orthomcl_lookup olo
                    WHERE    ome.ortho_id   = olo.ortho_id
                    AND      ome.cluster_id = ?
                    ORDER BY ome.org_tlc,
                             olo.db_id1);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($ortho_id);

    undef my @orthomcls;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @orthomcls, \@row;

    }

    return @orthomcls;

}


###############################################################################

sub draw_orthomcl_graph {

    my ($xaxis_ref, $yaxis_ref) = @_;

    my $my_graph = GD::Graph::bars->new(600, 160);

    my @data = ($xaxis_ref, $yaxis_ref);

    my $max = -1;

    foreach my $y (@{$yaxis_ref}) {

        $max = $y
            if $y > $max;

    }

    my $y_max_value   = $max;
    my $y_label_skip  = 'auto';
    my $y_tick_number = 'auto';

    if ($max == 1) {
        $y_max_value   = $max + 1;
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 2) {
        $y_label_skip  = 1;
        $y_tick_number = 2;
    } elsif ($max == 3) {
        $y_label_skip  = 1;
        $y_tick_number = 3;
    }

    if ($y_max_value > 6) {
        $y_max_value = ( (int($y_max_value/5) + 1)*5);
    } elsif ($y_max_value > 20) {
        $y_max_value = ( (int($y_max_value/10) + 1)*10);
    }

    $my_graph->set(y_min_value   => 0,
                   y_max_value   => $y_max_value,
                   y_label       => 'No. of orthologs',
                   y_label_skip  => $y_label_skip,
                   y_tick_number => $y_tick_number,
                   x_labels_vertical => 1,
                   cycle_clrs    => 1,
                   dclrs => ["#ffdfdf",
                             "#ccd7ff",
                             "#ccffcc",
                             "#ffffcc",
                             "#cce7ff",
                             "#ffccaa",
                             "#d2dbd5",
                             "#ffc7aa",
                             "#ffddcc",
                             "#bbebff",
                             "#eeeea2",
                             "#cceecc",
                             "#8ceffd",
                             "#ffdfff",
                             "#ffccff",
                             "#cceeff",
                             "#efe7cf",
                             "#ffdd75",
                             "#d1ffb3",
                             "#c9decb",
                             "#f0dcd5",
                             "#ccddff",
                             "#ccccff",
                             "#ffd7aa",
                             "#c9decb"]
                  ) or die $my_graph->error;

    $my_graph->set_x_axis_font(GD::gdSmallFont);
    $my_graph->set_y_axis_font(GD::gdSmallFont);

    my $gd = $my_graph->plot(\@data)
        or die $my_graph ->error;

    my $format = $my_graph->export_format;

    my $rand = int(rand(100000) );

    my ($fpath) = $TMPDIR =~ m|([a-zA-Z0-9_\-/\.]+)|;

    my $id = Website::Utilities::IdGenerator->get_unique_id();

    $fpath .= "/$id.$format";

    open GRAPH, ">$fpath"
        or die qq($fpath: $!);

    binmode GRAPH;

    print GRAPH $my_graph->plot(\@data)->$format;

    close GRAPH;

    return "$id.$format";

}


###############################################################################

sub get_val_results {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT *
                    FROM   vals_orthologs
                    WHERE  pombe_id = ?
                    OR     yeast_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    undef my @vals;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @vals, \@row;

    }

    return @vals;

}


###############################################################################

sub search_go_with_ids {

    my ($dbh, $search_go, $uni_id, $species_id, $local_search_gos) = @_;

    my $go_flag = 0;

 GO_SPE:
    foreach my $go_spe (@go_search_species) {

        if ($species_id eq $go_spe) {

            $go_flag = 1;

            last GO_SPE;

        }

    }

    if ($go_flag) {

        if ($species_id == 10) {

            $search_go =~ s/(At.+?)\.\d+$/$1/i;

        }

        push @{$local_search_gos}, lc $search_go
            if $search_go and defined $search_go;

        my $search_go2 = '';

        if ($species_id == 20) {

            $search_go2 = get_worm_gid($dbh, $search_go);

            push @{$local_search_gos}, lc $search_go2
                if $search_go2 and defined $search_go2;

        }

        push @{$local_search_gos}, lc $uni_id
            if $uni_id and defined $uni_id;

        #print "[$search_go] [$search_go2] [$uni_id] [@search_gos]\n";

        my $search_flag = 0;

        foreach my $sid (@search_gos) {

            next
                unless $sid;

            if (lc $search_go eq $sid) {

                $search_flag = 1;

                last;

            }

            if (lc $search_go2 eq $sid) {

                $search_flag = 1;

                last;

            }

            if (lc $uni_id eq $sid) {

                $search_flag = 1;

                last;

            }

        }

        if ($search_flag == 0) {

            my $go_ids = undef;

            if ($species_id != 40) {

                $go_ids = get_go_results($dbh,
                                         $species_tax_rev{$species_id},
                                         $search_go);

                push @search_gos, lc $search_go;

            }

            if (not defined $go_ids and $uni_id) {

                $go_ids = get_go_results_uni($dbh,
                                             $species_tax_rev{$species_id},
                                             $uni_id);

                push @search_gos, lc $uni_id;

            }

            if (defined $go_ids) {

                save_go_info($go_ids, $species_id);

            }

            if ($species_id == 20) {

                my $go_ids2 = undef;

                $go_ids2 = get_go_results($dbh,
                                          $species_tax_rev{$species_id},
                                          $search_go2);

                push @search_gos, lc $search_go2;

                if (defined $go_ids2) {

                    save_go_info($go_ids2, $species_id);

                }

            }

        }

    }

    return $local_search_gos;

}


###############################################################################

sub get_go_results {

    # TODO: if want 'NOT' terms, comment out line != 'NOT' in queries
    #   in this sub-routine and also in get_go_results_uni.

    # The rest of the code can deal with 'NOT' terms now.

    my ($dbh, $tax_id, $search_go) = @_;

    my $sth_query = undef;

    print ' ' x 2048;

    if ($tax_id == 3702) {

        my $string = qq(SELECT DISTINCT go_id,
                                        qualifier,
                                        evidence
                        FROM   go_mappings
                        WHERE  taxon           = ?
                        AND    database_name  != 'UniProt'
                        AND    qualifier      != 'NOT'
                        AND   (database_id     = ?
                        OR     database_symbol = ?
                        OR     db_synonym      LIKE ?) );

        $sth_query = $dbh->prepare($string);

        $sth_query->execute($tax_id, $search_go, $search_go, '%' . $search_go . '%');

    } else {

        my $string = qq(SELECT DISTINCT go_id,
                                        qualifier,
                                        evidence
                        FROM   go_mappings
                        WHERE  taxon           = ?
                        AND    database_name  != 'UniProt'
                        AND    qualifier      != 'NOT'
                        AND   (database_id     = ?
                        OR     database_symbol = ?) );

        $sth_query = $dbh->prepare($string);

        $sth_query->execute($tax_id, $search_go, $search_go);

    }

    print ' ' x 2048;

    undef my @go_ids;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @go_ids, [ $row[0], $row[1], $row[2] ];

    }

    #@go_ids =
    #    sort { lc $a cmp lc $b }
    #        keys %{ { map { $_->[0], 1 } @go_ids} };

    my $go_ids = undef;

    foreach my $gid (@go_ids) {

        push @{$go_ids}, [ $gid->[0], $search_go, $gid->[1], $gid->[2] ];

    }

    return $go_ids;

}


###############################################################################

sub get_go_results_uni {

    my ($dbh, $tax_id, $search_go) = @_;

    my $string = qq(SELECT DISTINCT go_id,
                                    qualifier,
                                    evidence
                    FROM   go_mappings
                    WHERE  taxon           = ?
                    AND    database_name   = 'UniProt'
                    AND    qualifier      != 'NOT'
                    AND   (database_id     = ?
                    OR     database_symbol = ?) );

    my $sth_query = $dbh->prepare($string);

    print ' ' x 2048;

    $sth_query->execute($tax_id, $search_go, $search_go);

    print ' ' x 2048;

    undef my @go_ids;

    while (my @row = $sth_query->fetchrow_array() ) {

        push @go_ids, [ $row[0], $row[1], $row[2] ];

    }

    #@go_ids =
    #    sort { lc $a cmp lc $b }
    #        keys %{ { map { $_, 1 } @go_ids} };

    my $go_ids = undef;

    foreach my $gid (@go_ids) {

        push @{$go_ids}, [ $gid->[0], $search_go, $gid->[1], $gid->[2] ];

    }

    return $go_ids;

}


###############################################################################

sub save_go_info {

    my ($go_ids, $species_id) = @_;

    my $go_links = '';

    foreach my $arr (@{$go_ids}) {

        my $go_id   = $arr->[0];
        my $prot_id = $arr->[1];
        my $qual    = $arr->[2];
        my $evid    = $arr->[3];
        push
            @{$all_go_ids->{$go_id}{$evid}{$species_3let{$species_id} } },
            [$prot_id, $qual];

    }

}


###############################################################################

sub print_go_table {

    my ($dbh, $orth_title, $local_search_gos) = @_;

    undef my @go_order;

    foreach my $go_id (sort keys %{$all_go_ids}) {

        my $go_type = get_go_type($dbh, $go_id);

        push @go_order, [$go_id, $go_type];

        @go_order = sort { $a->[1] cmp $b->[1] or $a->[0] <=> $b->[0] } @go_order;

    }

    undef my @go_rows;

    my $count = 0;

 GID:
    foreach my $go_term (@go_order) {

        my $go_id   = $go_term->[0];
        my $go_type = $go_term->[1];

        my $go_string = '';

        ($count, $go_string) = get_go_string($count, $go_id, $local_search_gos);

        my $go_desc = get_go_desc($dbh, $go_id);

        my $go_colour = $go_aspect_colour{$go_type};

        #my $href  = "http://www.godatabase.org/cgi-bin/amigo/go.cgi?query=$go_id";
        my $href  = "http://www.godatabase.org/cgi-bin/amigo/go.cgi?view=details&search_constraint=terms&depth=0&query=$go_id";
        my $title = 'AmiGO';

        my $aspect_href  = "http://www.geneontology.org/GO.doc.shtml#$go_aspect_href{$go_type}";
        my $aspect_title = $go_aspect_title{$go_type};

        $go_desc =~ s|(.{30,50} )|$1<br />|g;

        push(@go_rows, td({-align   => 'center',
                           -bgcolor => $go_colour},
                          [a({-href   => $href,
                              -style  => $gStyle,
                              -target => $gBlank,
                              -title  => $title},
                             $go_id),
                           $go_desc,
                           a({-href   => $aspect_href,
                              -style  => $gStyle,
                              -target => $gBlank,
                              -title  => $aspect_title},
                             $go_type),
                           $go_string]) );

    }

    undef my @go_headings;

    push(@go_headings, td({-align => 'center',
                           -style => 'font-style: italic'},
                          ['GO ID',
                           'GO term',
                           'GO aspect',
                           'Evidence codes and associations']) );

    undef my @go_table;

    push @go_table, @go_headings;

    push @go_table, @go_rows;

    print "<br />", h5("GO terms for $orth_title results: ");

    print ' ' x 2048;

    if ($count) {

        print "<p>", table({-class       => 'violet3',
                            -cellpadding => '2'
                            -width       => '80%'},
                           Tr(\@go_table) ), "</p>";

    } else {

        print "<p />None found.<p />";

    }

    print ' ' x 2048;

}


###############################################################################

sub get_go_string {

    my ($count, $go_id, $local_search_gos) = @_;

    my $uni_href  = "http://us.expasy.org/cgi-bin/niceprot.pl?";
    my $uni_title = 'UniProt';

    my $go_string = '';

 EVID:
    foreach my $evid (sort keys %{$all_go_ids->{$go_id} }) {

        my $evid_string = '';

    ORG:
        foreach my $org (sort keys %{$all_go_ids->{$go_id}{$evid} }) {

            my $org_string = '';

        MID:
            foreach my $mid (sort @{$all_go_ids->{$go_id}{$evid}{$org} }) {

                #print "MID: [$mid->[0]]\n";

            LID:
                foreach my $lid (sort @{$local_search_gos}) {

                    #print "LID: [$lid]\n";

                    if (lc $mid->[0] eq $lid) {

                        $count++;

                        my $href = '';

                        if ($mid->[0] =~ /^([OPQ][\d][A-Z\d]{3}\d)/i) {

                            $href = a({-href   => $uni_href . $mid->[0],
                                       -style  => $gStyle,
                                       -target => $gBlank,
                                       -title  => $uni_title},
                                      $mid->[0]);

                        } else {

                            $href = a({-href   => $species_hrefs{$org} . $mid->[0],
                                       -style  => $gStyle,
                                       -target => $gBlank,
                                       -title  => $species_href_titles{$org}},
                                      $mid->[0]);

                        }

                        $org_string .= $href;

                        if ($mid->[1] eq 'NOT') {

                            $org_string .= ' <font color="#f75d59">[NOT]</font>';

                        }

                        $org_string .= '<br />';

                        last LID;

                    }

                }

            }

            if ($org_string) {

                $org_string =~ s|<br />$||;

                my $bg_colour = $species_colour{$species_3let_rev{$org} };

                $org_string =
                    '<tr bgcolor="' . $bg_colour . '"><td align="left" width="20%"><em>' . $org .
                    '</em></td><td align="left" width="80%">' . $org_string . '</td></tr>';

                $evid_string .= $org_string;

            }

        }

        if ($evid_string) {

            my $lc_evid = lc $evid;
            my $uc_evid = uc $evid;

            my $evid_title  = $go_evid_title{$uc_evid};
            my $evid_colour = $go_evid_colour{$uc_evid};

            my $evid_link =
                "<a href='http://www.geneontology.org/GO.evidence.shtml#${lc_evid}' " .
                "style='$gStyle' title='$evid_title' target=$gBlank>$evid</a>";

            $evid_string =
                '<tr bgcolor="#ffffff"><td bgcolor="' . $evid_colour . '" align="left" width="20%">' .
                $evid_link . '</td><td bgcolor="#f5f5f5" align="left" width="80%">' .
                '<table cellpadding="2" width="100%">' . $evid_string . '</table></td></tr>';

            $go_string .= $evid_string;

        }

    }

    next GID
        unless $go_string;

    $go_string = '<table cellpadding="2" width="230">' . $go_string . '</table>';

    return ($count, $go_string);

}


###############################################################################

sub print_final_go_table {

    my ($dbh) = @_;

    undef my @go_order;

    foreach my $go_id (sort keys %{$all_go_ids}) {

        my $go_type = get_go_type($dbh, $go_id);

        push @go_order, [$go_id, $go_type];

        @go_order = sort { $a->[1] cmp $b->[1] or $a->[0] <=> $b->[0] } @go_order;

    }

    undef my @go_rows;

    my $count = 0;

 GID:
    foreach my $go_term (@go_order) {

        my $go_id   = $go_term->[0];
        my $go_type = $go_term->[1];

        my $go_string = '';

        ($count, $go_string) = get_final_go_string($count, $go_id);

        my $go_desc = get_go_desc($dbh, $go_id);

        #my $href  = "http://www.godatabase.org/cgi-bin/amigo/go.cgi?query=$go_id";
        my $href  = "http://www.godatabase.org/cgi-bin/amigo/go.cgi?view=details&search_constraint=terms&depth=0&query=$go_id";
        my $title = 'AmiGO';

        my $go_colour = $go_aspect_colour{$go_type};

        my $aspect_href  = "http://www.geneontology.org/GO.doc.shtml#$go_aspect_href{$go_type}";
        my $aspect_title = $go_aspect_title{$go_type};

        $go_desc =~ s|(.{30,50} )|$1<br />|g;

        push(@go_rows, td({-align   => 'center',
                           -bgcolor => $go_colour},
                          [a({-href   => $href,
                              -style  => $gStyle,
                              -target => $gBlank,
                              -title  => $title},
                             $go_id),
                           $go_desc,
                           a({-href   => $aspect_href,
                              -style  => $gStyle,
                              -target => $gBlank,
                              -title  => $aspect_title},
                             $go_type),
                           $go_string]) );

    }

    undef my @go_headings;

    push(@go_headings, td({-align => 'center',
                           -style => 'font-style: italic'},
                          ['GO ID',
                           'GO term',
                           'GO aspect',
                           'Evidence codes and associations']) );

    undef my @go_table;

    push @go_table, @go_headings;

    push @go_table, @go_rows;

    print "<p>", h4("GO terms: "), "</p>";

    print ' ' x 2048;

    if ($count) {

        print "<p>", table({-class       => 'violet3',
                            -cellpadding => '2',
                            -width       => '80%'},
                           Tr(\@go_table) ), "</p>";

    } else {

        print "<p />None found.<p />";

    }

    print ' ' x 2048;

}


###############################################################################

sub get_final_go_string {

    my ($count, $go_id) = @_;

    my $uni_href  = "http://us.expasy.org/cgi-bin/niceprot.pl?";
    my $uni_title = 'UniProt';

    my $go_string = '';

 EVID:
    foreach my $evid (sort keys %{$all_go_ids->{$go_id} }) {

        my $evid_string = '';

    ORG:
        foreach my $org (sort keys %{$all_go_ids->{$go_id}{$evid} }) {

            my $org_string = '';

        MID:
            foreach my $mid (sort @{$all_go_ids->{$go_id}{$evid}{$org} }) {

                #print "MID: [$mid->[0]]\n";

                $count++;

                my $href = '';

                if ($mid->[0] =~ /^([OPQ][\d][A-Z\d]{3}\d)/i) {

                    $href = a({-href   => $uni_href . $mid->[0],
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => $uni_title},
                              $mid->[0]);

                } else {

                    $href = a({-href   => $species_hrefs{$org} . $mid->[0],
                               -style  => $gStyle,
                               -target => $gBlank,
                               -title  => $species_href_titles{$org}},
                              $mid->[0]);

                }

                $org_string .= $href;

                if ($mid->[1] eq 'NOT') {

                    $org_string .= ' <font color="#F75D59">[NOT]</font>';

                }

                $org_string .= '<br />';

            }

            if ($org_string) {

                $org_string =~ s|<br />$||;

                my $bg_colour = $species_colour{$species_3let_rev{$org} };

                $org_string =
                    '<tr bgcolor="' . $bg_colour . '"><td align="left" width="20%"><em>' . $org .
                    '</em></td><td align="left" width="80%">' . $org_string . '</td></tr>';

                $evid_string .= $org_string;

            }

        }

        if ($evid_string) {

            my $lc_evid = lc $evid;
            my $uc_evid = uc $evid;

            my $evid_title  = $go_evid_title{$uc_evid};
            my $evid_colour = $go_evid_colour{$uc_evid};

            my $evid_link =
                "<a href='http://www.geneontology.org/GO.evidence.shtml#${lc_evid}' " .
                "style='$gStyle' title='$evid_title' target=$gBlank>$evid</a>";

            $evid_string =
                '<tr bgcolor="#ffffff"><td bgcolor="' . $evid_colour . '" align="left" width="20%">' .
                $evid_link . '</td><td bgcolor="#f5f5f5" align="left" width="80%">' .
                '<table cellpadding="2" width="100%">' . $evid_string . '</table></td></tr>';

            $go_string .= $evid_string;

        }

    }

    next GID
        unless $go_string;

    $go_string = '<table cellpadding="2" width="230">' . $go_string . '</table>';

    return ($count, $go_string);

}


###############################################################################

sub get_go_desc {

    my ($dbh, $go_id) = @_;

    my $string = qq(SELECT go_desc
                    FROM   go_terms
                    WHERE  go_id = ?);

    my $sth_query = $dbh->prepare($string);

    print ' ' x 2048;

    $sth_query->execute($go_id);

    print ' ' x 2048;

    my @row = $sth_query->fetchrow_array();

    return ($row[0]);

}


###############################################################################

sub get_go_type {

    my ($dbh, $go_id) = @_;

    my $string = qq(SELECT aspect
                    FROM   go_terms
                    WHERE  go_id = ?);

    my $sth_query = $dbh->prepare($string);

    print ' ' x 2048;

    $sth_query->execute($go_id);

    print ' ' x 2048;

    my @row = $sth_query->fetchrow_array();

    return ($row[0]);

}


###############################################################################

sub get_pombe_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT GeneDB_systematic_id
                    FROM   pombe_gene
                    WHERE  GeneDB_systematic_id = ?
                    OR     GeneDB_primary       = ?
                    OR     PombePD_Systematic   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_budding_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT SGDID
                    FROM   budding_gene
                    WHERE  SGD_symbol   = ?
                    OR     SGD_sys_name = ?
                    OR     SGDID        = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_budding_id2 {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT SGD_sys_name
                    FROM   budding_gene
                    WHERE  SGD_symbol   = ?
                    OR     SGD_sys_name = ?
                    OR     SGDID        = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_gid {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT WG.WB_id
                    FROM   worm_gene WG,
                           worm_pep  WP
                    WHERE  WG.CE_id = WP.CE_id
                    AND   (WP.WP_id = ?
                    OR     WG.CE_id = ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('WP:' . $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_gid2 {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT WB_id
                    FROM   worm_gene
                    WHERE  CE_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_wid {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT WG.CE_id
                    FROM   worm_gene WG,
                           worm_pep  WP
                    WHERE  WG.CE_id   = WP.CE_id
                    AND   (WG.WB_id   = ?
                    OR     WG.WB_name = ?
                    OR     WP.WP_id   = ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, 'WP:' . $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_wid2 {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT CE_id
                    FROM   worm_pep  WP
                    WHERE  WP_id   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('WP:' . $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_pid {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT WP.WP_id
                    FROM   worm_gene WG,
                           worm_pep  WP
                    WHERE  WG.CE_id   = WP.CE_id
                    AND   (WG.WB_id   = ?
                    OR     WG.WB_name = ?
                    OR     WG.CE_id   = ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    $row[0] =~ s/^WP://;

    return $row[0];

}


###############################################################################

sub get_worm_pid2 {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT WP_id
                    FROM   worm_pep
                    WHERE  CE_id = ?
                    OR     WP_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, 'WP:' . $db_id);

    my @row = $sth_query->fetchrow_array();

    $row[0] =~ s/^WP://;

    return $row[0];

}


###############################################################################

sub get_fly_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT FB_id
                    FROM   fly_gene
                    WHERE  FB_name = ?
                    OR     DM_id   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_fly_id2 {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT DM_id
                    FROM   fly_gene
                    WHERE  FB_name = ?
                    OR     FB_id   = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_arab_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT TAIR_id
                    FROM   arab_gene
                    WHERE  prot_acc LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id . '%');

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_arab_gi {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT prot_gi
                    FROM   arab_gene
                    WHERE  TAIR_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_mouse_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT MGI_id
                    FROM   mouse_gene
                    WHERE  MGI_id   = ?
                    OR     MGI_name = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    $row[0] =~ s/MGI://;

    return $row[0];

}


###############################################################################

sub get_rat_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT RGD_id
                    FROM   rat_gene
                    WHERE  RGD_id   = ?
                    OR     RGD_name = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_eco_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT eco_id
                    FROM   eco_gene
                    WHERE  eco_id   = ?
                    OR     eco_name = ?
                    OR     uni_id   = ?
                    OR     ref_gi   = ?
                    OR     ref_acc  LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, $db_id, $db_id, $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_eco_ref_acc {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT ref_acc
                    FROM   eco_gene
                    WHERE  eco_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_eco_ref_gi {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT ref_gi
                    FROM   eco_gene
                    WHERE  eco_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_pombe_uni_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT uni_id
                    FROM   pombe_gene
                    WHERE  GeneDB_systematic_id = ?
                    OR     GeneDB_primary       = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_uni_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT uni_id
                    FROM   worm_pep
                    WHERE  WP_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('WP:' . $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_mouse_uni_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT uni_id
                    FROM   mouse_gene
                    WHERE  MGI_id   = ?
                    OR     MGI_name = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('MGI:' . $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    $row[0] =~ s/^\s+//;
    $row[0] =~ s/\s+$//;

    if ($row[0] =~ / /) {

        $row[0] = (split / /, $row[0])[0];

    }

    return $row[0];

}


###############################################################################

sub get_rat_uni_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT uni_id
                    FROM   rat_gene
                    WHERE  RGD_id   = ?
                    OR     RGD_name = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_eco_uni_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT uni_id
                    FROM   eco_gene
                    WHERE  eco_id  = ?
                    OR     ref_gi  = ?
                    OR     ref_acc LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id, $db_id, $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_pombe_id_from_uni {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT GeneDB_systematic_id
                    FROM   pombe_gene
                    WHERE  uni_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_worm_id_from_uni {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT WP_id
                    FROM   worm_pep
                    WHERE  uni_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    $row[0] =~ s/^WP://;

    return $row[0];

}


###############################################################################

sub get_mouse_id_from_uni {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT MGI_id
                    FROM   mouse_gene
                    WHERE  uni_id LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute('%' . $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    $row[0] =~ s/^MGI://;

    return $row[0];

}


###############################################################################

sub get_rat_id_from_uni {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT RGD_id
                    FROM   rat_gene
                    WHERE  uni_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_eco_id_from_uni {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT eco_id
                    FROM   eco_gene
                    WHERE  uni_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_ens_from_uni {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT DB_name,
                           DB_id,
                           ALT_ENS_id
                    FROM   ipi_lookup
                    WHERE  species_id = ?
                    AND ( (DB_id      = ?
                    AND    DB_name    IN ('SP', 'TR') )
                    OR     ALT_USP_id LIKE ?
                    OR     ALT_UTR_id LIKE ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, $db_id, '%' . $db_id . '%', '%' . $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    my $ens_id = '';

    if ($row[0] eq 'ENSEMBL') {

        $ens_id = $row[1];

    } else {

        $ens_id = (split /;/, $row[2])[0];

    }

    return $ens_id;

}


###############################################################################

sub get_gi_from_id {

    my ($dbh, $db_id, $tax_id) = @_;

    my $string = qq(SELECT gi_number
                    FROM   homologene
                    WHERE  tax_id            = ?
                    AND   (gene_symbol       = ?
                    OR     gi_number         = ?
                    OR     protein_accession = ?) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($tax_id, $db_id, $db_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_id_from_gi {

    my ($dbh, $db_id, $tax_id) = @_;

    my $string = qq(SELECT gene_symbol
                    FROM   homologene
                    WHERE  tax_id    = ?
                    AND    gi_number = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($tax_id, $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_info_from_ens {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT *
                    FROM   ipi_lookup
                    WHERE  species_id = ?
                    AND   (ALT_ENS_id LIKE ?
                    OR    (DB_id      = ?
                    AND    DB_name    = 'ENSEMBL') ) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, '%' . $db_id . '%', $db_id);

    my @row = $sth_query->fetchrow_array();

    my $fgene = (split /;/, $row[12])[0];

    my $gene_id = (split /,/, $fgene)[0];

    my $fgi = (split /;/, $row[16])[0];

    $fgi =~ s/^GI://;

    my $uni_id = '';

    if ($row[1] eq 'SP' or $row[1] eq 'TR') {

        $uni_id = $row[2];

    } elsif ($row[4]) {

        $uni_id = (split /;/, $row[4])[0];

    } elsif ($row[5]) {

        $uni_id = (split /;/, $row[5])[0];

    }

    my $array_ref = [$db_id, $fgi, '', $gene_id, '', $uni_id, '', ''];

    #print Dumper $array_ref;

    return $array_ref;

}


###############################################################################

sub get_name_from_ens {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT MO_DB_id,
                           NCBI_gene_id
                    FROM   ipi_lookup
                    WHERE  species_id = ?
                    AND   (ALT_ENS_id LIKE ?
                    OR    (DB_id      = ?
                    AND    DB_name    = 'ENSEMBL') ) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, '%' . $db_id . '%', $db_id);

    my @row = $sth_query->fetchrow_array();

    #print "[@row]\n";

    my $gene_name = '';

    if ($row[0]) {

        $gene_name = (split /;/, $row[0])[0];

        if ($species_id == 150) {

            $gene_name = 'RGD:' . $gene_name;

        }

    } else {

        $gene_name = (split /;/, $row[1])[0];

        $gene_name = 'GI:' . $gene_name
            if $gene_name;

    }

    return $gene_name;

}


###############################################################################

sub get_ens_from_gi {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT DB_name,
                           DB_id,
                           ALT_ENS_id
                    FROM   ipi_lookup
                    WHERE  species_id  = ?
                    AND    RS_GI_PI_id LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, '%' . $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    #print "[$db_id] [@row]\n";

    my $ens_id = '';

    if ($row[0] eq 'ENSEMBL') {

        $ens_id = $row[1];

    } else {

        $ens_id = (split /;/, $row[2])[0];

    }

    return $ens_id;

}


###############################################################################

sub get_ipi_info_from_gi {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT DB_name,
                           DB_id,
                           ALT_USP_id,
                           ALT_ENS_id,
                           ALT_UTR_id,
                           EMBL_acc,
                           MO_DB_id,
                           NCBI_gene_id,
                           UniGene_id
                    FROM   ipi_lookup
                    WHERE  species_id  = ?
                    AND    RS_GI_PI_id LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, '%' . $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    #print "DATA: [@row]\n";

    return '';

}


###############################################################################

sub get_gi_from_ens {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT RS_GI_PI_id
                    FROM   ipi_lookup
                    WHERE  species_id = ?
                    AND   (ALT_ENS_id LIKE ?
                    OR    (DB_id      = ?
                    AND    DB_name    = 'ENSEMBL') ) );

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, '%' . $db_id . '%', $db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_ens_from_ids {

    my ($dbh, $db_id, $species_id) = @_;

    my $string = qq(SELECT DB_name,
                           DB_id,
                           ALT_ENS_id,
                           MO_DB_id,
                           NCBI_gene_id,
                           ALT_USP_id,
                           ALT_UTR_id,
                           RS_GI_PI_id
                    FROM   ipi_lookup
                    WHERE (species_id   = ?
                    AND ( (DB_id        = ?
                    AND    DB_name      IN ('SP', 'TR') )
                    OR     MO_DB_id     LIKE ?
                    OR     NCBI_gene_id LIKE ?
                    OR     ALT_USP_id   LIKE ?
                    OR     ALT_UTR_id   LIKE ?
                    OR     RS_GI_PI_id  LIKE ?) ) );


    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($species_id, $db_id,
                        '%,' . $db_id . ';',
                        '%,' . $db_id . ';',
                        '%' . $db_id . '%',
                        '%' . $db_id . '%',
                        '%' . $db_id . '%');

    undef my @ens_ids;

    my $ens_id = '';

    while (my @row = $sth_query->fetchrow_array() ) {

        #print "[$row[3]] [$row[4]] [$row[5]] [$row[6]] [$row[7]]\n";

        if ($row[0] eq 'ENSEMBL') {

            $ens_id = $row[1];

        } else {

            $ens_id = (split /;/, $row[2])[0];

            if ($ens_id =~ /^HAVANA/) {

                my $tmp_id = (split /;/, $row[2])[1];

                $ens_id = $tmp_id
                    if defined $tmp_id and $tmp_id;

            }

        }

        push @ens_ids, $ens_id
            if $ens_id;

        #print "[$ens_id]\n";

    }

    return @ens_ids;

}


###############################################################################

sub get_uniprot_id {

    my ($dbh, $gi, $tax_id) = @_;

    undef my @uni_ids;

    my $string = qq(SELECT gene_id
                    FROM   gi_lookup
                    WHERE  tax_id   = ?
                    AND    prot_id  = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($tax_id, $gi);

    my @row = $sth_query->fetchrow_array();

    print ' ' x 2048;

    my $string2 = qq(SELECT prot_acc
                     FROM   gi_lookup
                     WHERE  gene_id = ?
                     AND    tax_id  = ?
                     AND    prot_acc NOT LIKE 'NP_%'
                     AND    prot_acc NOT LIKE 'YP_%'
                     AND    prot_acc NOT LIKE 'XP_%');

    my $sth_query2 = $dbh->prepare($string2);

    $sth_query2->execute($row[0], $tax_id);

    while (my @row2 = $sth_query2->fetchrow_array() ) {

        print ' ' x 2048;

        last
            unless defined $row2[0] or $row2[0];

        if ($row2[0] =~ /^([OPQ][\d][A-Z\d]{3}\d)/) {

            return $1;

        }

        my $string3 = qq(SELECT pri_uni_acc
                         FROM   uniprot_lookup
                         WHERE  gb_prot_acc = ?);

        my $sth_query3 = $dbh->prepare($string3);

        $sth_query3->execute($row2[0]);

        @uni_ids = $sth_query3->fetchrow_array();

        print ' ' x 2048;

        last
            if defined $uni_ids[0] and $uni_ids[0];

    }

    $uni_ids[0] = ''
        unless defined $uni_ids[0] or $uni_ids[0];

    return $uni_ids[0];

}


###############################################################################

sub get_uniprot_id2 {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT uni_id
                    FROM   yogy_uniprot_lookup
                    WHERE  yogy_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_yogy_id {

    my ($dbh, $db_id) = @_;

    my $string = qq(SELECT yogy_id
                    FROM   yogy_uniprot_lookup
                    WHERE  uni_id = ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($db_id);

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}


###############################################################################

sub get_prot_id {

    my ($dbh, $db_id, $tax_id) = @_;

    my $string = qq(SELECT prot_id
                    FROM   gi_lookup
                    WHERE  tax_id   = ?
                    AND    prot_acc LIKE ?);

    my $sth_query = $dbh->prepare($string);

    $sth_query->execute($tax_id, $db_id . '%');

    my @row = $sth_query->fetchrow_array();

    return $row[0];

}
