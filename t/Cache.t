use strict;
use warnings;
use Test::More;
use Digest::MD5 'md5_hex';

BEGIN { use_ok('Nginx::FastCGI::Cache') };

# default args
ok(my $nginx_cache = Nginx::FastCGI::Cache->new);
is('httpGETwww.perltricks.com/admin', $nginx_cache->_build_fastcgi_key('http://www.perltricks.com/admin'));
is('200d51ef65b0a76de421f8f1ec047854', md5_hex('httpGETperltricks.com/'));
is('/var/nginx/cache/4/85/200d51ef65b0a76de421f8f1ec047854', $nginx_cache->_build_path('200d51ef65b0a76de421f8f1ec047854'));

# setup tmp dir
mkdir '/tmp/nginx_fastcgi_cache';

SKIP: {
    skip 'failed to create temp directory', 6 unless -e '/tmp/nginx_fastcgi_cache' and -x '/tmp/nginx_fastcgi_cache';

    # setup the folder structure
    mkdir '/tmp/nginx_fastcgi_cache/4' if -e '/tmp/nginx_fastcgi_cache' and -x '/tmp/nginx_fastcgi_cache';
    mkdir '/tmp/nginx_fastcgi_cache/4/85' if -e '/tmp/nginx_fastcgi_cache/4' and -x '/tmp/nginx_fastcgi_cache/4';
    mkdir '/tmp/nginx_fastcgi_cache/4/85/7' if -e '/tmp/nginx_fastcgi_cache/4/85' and -x '/tmp/nginx_fastcgi_cache/4/85';
    if (-e '/tmp/nginx_fastcgi_cache/4/85/7' and -x '/tmp/nginx_fastcgi_cache/4/85/7') {
        open (my $cache_file, '>', '/tmp/nginx_fastcgi_cache/4/85/7/200d51ef65b0a76de421f8f1ec047854') or die "unable to write test cache file $!";
        print $cache_file 'test data';
        close $cache_file;
    }
    ok($nginx_cache = Nginx::FastCGI::Cache->new({ levels => [ 1, 2, 1 ], location => '/tmp/nginx_fastcgi_cache' }));
    is('/tmp/nginx_fastcgi_cache/4/85/7/200d51ef65b0a76de421f8f1ec047854', $nginx_cache->_build_path('200d51ef65b0a76de421f8f1ec047854'));
    ok($nginx_cache->purge_file('http://perltricks.com/'));
    ok(! -e '/tmp/nginx_fastcgi_cache/4/85/7/200d51ef65b0a76de421f8f1ec047854');

    if (-e '/tmp/nginx_fastcgi_cache/4/85/7' and -x '/tmp/nginx_fastcgi_cache/4/85/7') {
        open (my $cache_file, '>', '/tmp/nginx_fastcgi_cache/4/85/7/200d51ef65b0a76de421f8f1ec047854') or die "unable to write test cache file $!";
        print $cache_file 'test data';
        close $cache_file;
    }
    ok($nginx_cache->purge_cache);
    ok(! -e '/tmp/nginx_fastcgi_cache/4/85/7/200d51ef65b0a76de421f8f1ec047854');
};

# exceptions
my $new_too_many_levels = eval {Nginx::FastCGI::Cache->new({levels => [qw/1 2 3 4/]})};
ok($new_too_many_levels);

my $new_zero_levels = eval {Nginx::FastCGI::Cache->new({levels => []})};
ok($new_zero_levels);

my $new_wrong_type_levels = eval {Nginx::FastCGI::Cache->new({levels => 1})};
ok($new_wrong_type_levels);


done_testing();
