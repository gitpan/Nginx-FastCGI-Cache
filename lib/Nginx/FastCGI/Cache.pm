use 5.12.1;
use warnings;

package Nginx::FastCGI::Cache;
$Nginx::FastCGI::Cache::VERSION = '0.004';
use Digest::MD5 'md5_hex';
use URI;
use feature qw/switch say/;
use Carp;

# ABSTRACT: Conveniently manage the nginx fastcgi cache

sub new {
    my ( $class, $args ) = @_;
    my $self = {};

    # directory must exist
    if ( exists $args->{location}
        and -e $args->{location} )
    {
        $self->{location} = $$args{location};
    }
    else {
        $self->{location} = '/var/nginx/cache';
    }

    # Must be 1-3 levels and have a value of 1 or 2
    if (    exists $args->{levels}
        and ref $args->{levels} eq 'ARRAY'
        and @{ $args->{levels} } > 0
        and @{ $args->{levels} } < 4
        and grep { $_ > 0 and $_ < 3 } @{ $args->{levels} } )
    {
        $self->{levels} = $args->{levels};
    }
    else {
        $self->{levels} = [ 1, 2 ];
    }

    # check only valid fascgi cache key variables used
    if (    exists $args->{fastcgi_cache_key}
        and ref $args->{fastcgi_cache_key} eq 'ARRAY'
        and @{ $args->{fastcgi_cache_key} } > 0
        and @{ $args->{fastcgi_cache_key} } ==
        grep /scheme|request_method|host|request_uri/,
        @{ $args->{fastcgi_cache_key} } )
    {
        $self->{fastcgi_cache_key} = $args->{fastcgi_cache_key};
    }
    else {
        $self->{fastcgi_cache_key} =
          [qw/scheme request_method host request_uri/];
    }

    return bless $self, $class;
}

# builds plaintext key using the fastcgi_cache_key elements
sub _build_fastcgi_key {
    my ( $self, $url ) = @_;
    croak "missing url argument $!" unless $url;

    my $uri = URI->new($url);
    my $fastcgi_key;

    foreach ( @{ $self->{fastcgi_cache_key} } ) {
        given ($_) {
            when ('scheme') {
                $fastcgi_key .= $uri->scheme;
            }
            when ('request_method') {
                $fastcgi_key .= 'GET';
            }
            when ('host') {
                $fastcgi_key .= $uri->host;
            }
            when ('request_uri') {
                $fastcgi_key .= $uri->path || '/';
            }
        }
    }
    return $fastcgi_key;
}

sub purge_file {
    my ( $self, $url ) = @_;
    croak "missing url argument $!" unless $url;

    my $md5_key = md5_hex( $self->_build_fastcgi_key($url) );
    my $path    = $self->_build_path($md5_key);
    return $self->_purge_file($path);
}

sub _purge_file {
    my ( $self, $path_to_purge ) = @_;
    croak "missing path argument $!" unless $path_to_purge;

    if ( -e $path_to_purge and -w $path_to_purge ) {
        unlink $path_to_purge
          or carp "unable to purge cache at $path_to_purge $!";
        return 1;
    }
    carp "cache does not exist or is not writable at $path_to_purge";
    return 0;
}

sub purge_cache {
    my $self = shift;
    $self->{count_of_files_deleted} = 0;
    $self->_purge_cache( $self->{location} );
    return $self->{count_of_files_deleted};
}

# purge entire cache directory
sub _purge_cache {
    my ( $self, $dir ) = @_;
    croak "missing directory argument" unless $dir;

    $dir .= '/' unless '/' eq substr $dir, -1;

    opendir( my $DH, $dir ) or croak "Failed to open $dir $!";

    while ( readdir $DH ) {
        my $path = $dir . $_;
        if ( -d $path ) {

            # recurse but ignore Unix symlinks . and ..
            $self->_purge_cache($path) if $_ !~ /^\.{1,2}$/;
        }
        elsif ( -f $path ) {
            $self->{count_of_files_deleted} += $self->_purge_file($path);
        }
    }
}

# builds absolute path of file to purge
sub _build_path {
    my ( $self, $md5_key ) = @_;
    croak "missing md5 key argument $!" unless $md5_key;

    my $path = $self->{location};
    my $md5_path_key = $md5_key;    #the last few chars form the directory path
    for ( @{ $self->{levels} } ) {
        $path .= '/' . substr $md5_path_key, -$_;
        $md5_path_key = substr $md5_path_key, 0, -$_;
    }
    return "$path/$md5_key";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Nginx::FastCGI::Cache - Conveniently manage the nginx fastcgi cache

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Nginx::FastCGI::Cache;

    # args are optional, these are the default values
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

=head2 purge_file

Deletes the nginx cached file for a particular URL - requires a URL as an
argument.

=head2 purge_cache

Deletes all nginx cached files in the nginx cache directory.

=head1 AUTHOR

David Farrell <sillymoos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Farrell.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
