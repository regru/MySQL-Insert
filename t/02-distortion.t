#
#===============================================================================
#
#         FILE:  02-distortion.t
#
#  DESCRIPTION:  Distortion tests. Some uncommon cases.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  31.07.2008 17:56:21 MSD
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
	id int PRIMARY KEY auto_increment,
	word varchar(64) NOT NULL default "anotherbrick",
	number float default 0.0
    )
');

{
    my $inserter = new MySQL::Insert( $dbh, 'testtable', 
	[ qw/word number/ ] );

    $inserter->insert_row(
	{
	    word => 'Remember',
	    number => \'10 + 10 * 2 + 3.14',
	}
    );

    $inserter->insert_row(
	{
	    word => \'NOW()',
	    number => '10',
	}
    );

    $inserter->insert_row(
	{
	    word => \'',
	    number => '3.14',
	}
    );

    $inserter->insert_row(
	{
	    word => \'CONCAT("vasya", "masha")',
	    number => '2.71',
	}
    );
}

is( $dbh->selectrow_array('SELECT COUNT(*) FROM testtable'), 4, '4 rows inserted');

my $all_the_rows = $dbh->selectall_hashref( 
    'SELECT * FROM testtable',
    'id'
);
delete $_->{id} foreach values %$all_the_rows;

is_deeply( $all_the_rows->{1}, 
    {
	word => 'Remember',
	number => 33.14,
    },
    'rows inserted'
);

like ( $all_the_rows->{2}{word}, qr/\d+-/, 'NOW() call ok' );

is_deeply( [ @$all_the_rows{3,4} ],
    [
	{
	    word    => '',
	    number  => 3.14,
	},
	{
	    word    => "vasyamasha",
	    number  => 2.71,
	}
    ],
    'concat data'
);
