use strict;
use warnings;
use Test::More;
use Digest::MD5 'md5_hex';
use File::Temp 'tempdir';

BEGIN { use_ok('Nginx::FastCGI::Cache') }

my $temp_dir = tempdir( CLEANUP => 1 );

# default args
ok( my $nginx_cache = Nginx::FastCGI::Cache->new( { location => $temp_dir } ) );
is( 'httpGETwww.perltricks.com/admin',
    $nginx_cache->_build_fastcgi_key('http://www.perltricks.com/admin') );
is( '200d51ef65b0a76de421f8f1ec047854', md5_hex('httpGETperltricks.com/') );
is(
    "$temp_dir/4/85/200d51ef65b0a76de421f8f1ec047854",
    $nginx_cache->_build_path('200d51ef65b0a76de421f8f1ec047854')
);

SKIP: {
    skip 'failed to create temp directory', 6
      unless -e $temp_dir and -x $temp_dir;

    # setup the folder structure
    mkdir "$temp_dir/4"      if -e "$temp_dir";
    mkdir "$temp_dir/4/85"   if -e "$temp_dir/4";
    mkdir "$temp_dir/4/85/7" if -e "$temp_dir/4/85";
    if ( -e "$temp_dir/4/85/7" ) {
        open( my $cache_file,
            '>', "$temp_dir/4/85/7/200d51ef65b0a76de421f8f1ec047854" )
          or die "unable to write test cache file $!";
        print $cache_file "test data";
        close $cache_file;
    }
    ok(
        $nginx_cache = Nginx::FastCGI::Cache->new(
            { levels => [ 1, 2, 1 ], location => $temp_dir }
        )
    );
    is(
        "$temp_dir/4/85/7/200d51ef65b0a76de421f8f1ec047854",
        $nginx_cache->_build_path('200d51ef65b0a76de421f8f1ec047854')
    );
    ok( $nginx_cache->purge_file('http://perltricks.com/') );
    ok( !-e "$temp_dir/4/85/7/200d51ef65b0a76de421f8f1ec047854" );

    if ( -e "$temp_dir/4/85/7" and -x "$temp_dir/4/85/7" ) {
        open( my $cache_file,
            '>', "$temp_dir/4/85/7/200d51ef65b0a76de421f8f1ec047854" )
          or die "unable to write test cache file $!";
        print $cache_file 'test data';
        close $cache_file;
        ok( $nginx_cache->purge_cache );
        ok( !-e "$temp_dir/4/85/7/200d51ef65b0a76de421f8f1ec047854" );
    }
}

# exceptions
my $missing_location = eval { Nginx::FastCGI::Cache->new };
ok($@);

my $invalid_location =
  eval { Nginx::FastCGI::Cache->new( { location => '/non/existent/place' } ) };
ok($@);

my $new_too_many_levels = eval {
    Nginx::FastCGI::Cache->new(
        { location => $temp_dir, levels => [qw/1 2 3 4/] } );
};
ok($@);

my $new_invalid_levels = eval {
    Nginx::FastCGI::Cache->new(
        { location => $temp_dir, levels => [qw/9 2 3/] } );
};
ok($@);

my $new_zero_levels =
  eval { Nginx::FastCGI::Cache->new( { location => $temp_dir, levels => [] } ) };
ok($@);

my $new_wrong_type_levels =
  eval { Nginx::FastCGI::Cache->new( { location => $temp_dir, levels => 1 } ) };
ok($@);

my $new_invalid_keys = eval {
    Nginx::FastCGI::Cache->new(
        {
            location          => $temp_dir,
            fastcgi_cache_key => [qw/schema request_method host/]
        }
    );
};
ok($@);

my $new_zero_keys = eval {
    Nginx::FastCGI::Cache->new(
        {
            location          => $temp_dir,
            fastcgi_cache_key => []
        }
    );
};
ok($@);

my $new_wrong_type_keys = eval {
    Nginx::FastCGI::Cache->new(
        {
            location          => $temp_dir,
            fastcgi_cache_key => 1
        }
    );
};
ok($@);

done_testing();
