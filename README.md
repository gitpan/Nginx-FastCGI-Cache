# NAME

Nginx::FastCGI::Cache - Conveniently manage the nginx fastcgi cache

# VERSION

version 0.005

# SYNOPSIS

    use Nginx::FastCGI::Cache;

    # location is mandatory, rest are optional, these are the default values
    my $nginx_cache
        = Nginx::FastCGI::Cache->new({
            fastcgi_cache_key => [qw/scheme request_method host request_uri/],
            location          => '/var/nginx/cache',
            levels            => [ 1, 2 ],
    });

    # delete all cached files
    $nginx->purge_cache;

    # delete the cached file for this url only
    $nginx->purge_file('http://perltricks.com/');

# METHODS

## new

Returns a new Nginx::FastCGI::Cache object. Location is the only mandatory
argument, and the directory must exist and be executable (aka readable) by the
Perl process in order to be valid. The other two arguments accepted are levels
and fastcgi\_cache\_key. These default to the standard nginx settings (see the
[nginx fastcgi
documentation](https://metacpan.org/pod/nginx.org#en-docs-http-ngx_http_fastcgi_module.html)).

## purge\_file

Deletes the nginx cached file for a particular URL - requires a URL as an
argument.

## purge\_cache

Deletes all nginx cached files in the nginx cache directory.

# BUGS / LIMITATIONS

- The fastcgi\_cache\_key only acccepts: scheme, request\_method, host, and
request\_uri as keys. This shouldn't be an issue as it's the recommended
convention, but let me know if further variables would be useful.
- When request\_method is included in the fastcgi\_cache\_key (and you should, to
avoid caching HEAD requests and returning them for GET requests with the same
URL) only GET is supported. If there is demand for it, I can include other
methods as well.
- I tested this module on Linux Fedora 17 and 19 and with nginx v1.0.15 and
v1.4.6. In testing with nginx v1.4.6, the caching function of nginx was
unreliable and would somtimes not resume caching following a cache purge.

# AUTHOR

David Farrell <sillymoos@cpan.org>, [PerlTricks.com](http://perltricks.com)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Farrell.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
