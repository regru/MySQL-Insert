#
#===============================================================================
#
#         FILE:  01-insert.t
#
#  DESCRIPTION:  Insertion test.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  31.07.2008 17:00:32 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 5;                      # last test to print

use DBI;
use MySQL::Insert;
use Data::Dumper;

my $dbh = DBI->connect('dbi:mysql:'. ($ENV{MYSQL_TEST_DB} || 'test'), 
    $ENV{MYSQL_TEST_USER}, 
    $ENV{MYSQL_TEST_PASSWORD},
) or die $DBI::errstr;


isa_ok( $dbh, 'DBI::db', 'DB handler' );

$dbh->do('DROP TABLE IF EXISTS testtable');
$dbh->do('
    CREATE TABLE testtable (
	word varchar(64) NOT NULL default "anotherbrick",
	number float default 0.0
    )
');

{
    $MySQL::Insert::MAX_ROWS_TO_QUERY = 100;

    my $inserter = new MySQL::Insert( $dbh, 'testtable', [ qw/word number/ ]);
    isa_ok( $inserter, 'MySQL::Insert', 'inserter instance');

    my $rows_to_insert = generate_rows_to_insert();
    # die Dumper( scalar @$rows_to_insert );

    foreach my $row (@$rows_to_insert) {
	$inserter->insert_row( $row );
    }

    my $should_insert_cnt = int( scalar( @$rows_to_insert ) / 100 ) * 100;

    is( $dbh->selectrow_array('SELECT COUNT(*) FROM testtable'),
	$should_insert_cnt,
	'inserted above threshhold'
    );

    undef $inserter;

    my $all_the_rows = $dbh->selectall_arrayref(
	'SELECT * FROM testtable',
	{ Slice => {} },
    );

    is_deeply( $all_the_rows, $rows_to_insert, 'inserted ok' );

    $dbh->do('DROP TABLE IF EXISTS testtable');
    $dbh->do('
	CREATE TABLE testtable (
	    word varchar(64),
	    number float default 0.0,
	    PRIMARY KEY ( word )
	)
    ');

    $inserter = new MySQL::Insert( $dbh, 'testtable', [ qw/word number/ ],
	on_duplicate_update => { word => \ "CONCAT('fld_val','4')", number => 4 },
	statement => 'INSERT'
    );

    $inserter->insert_row( [ 'fld_val1', 1 ], { word => 'fld_val2', number => 2 }, [ 'fld_val1', 1 ] );
    undef $inserter;

    $all_the_rows = $dbh->selectall_arrayref(
	'SELECT * FROM testtable',
        { Slice => {} },
    );

    is_deeply( $all_the_rows,
	[
	    { number => 4, word => 'fld_val4' },
	    { number => 2, word => 'fld_val2' }
	],
	'multirow insert' );
}

#---------------------------------------------------------------------------
#  UTILITY FUNCTIONS
#---------------------------------------------------------------------------
sub generate_rows_to_insert {
    my $filename = shift || $INC{'MySQL/Insert.pm'};

    my @rows_to_insert;

    for (my $i = 0; $i < 256; $i++) {
	my $float  = sprintf( "%.3f", rand 3.1415926535897 ) . '1';

	push @rows_to_insert, {
	    word => "XYZ#$i",
	    number => $float,
	};
    }

    return \@rows_to_insert;
}
