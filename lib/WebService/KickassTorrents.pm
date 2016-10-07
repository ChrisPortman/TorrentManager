#!/usr/bin/env false

package WebService::KickassTorrents;

    our $VERSION = 0.01;
    
    use strict;
    use warnings;
    use LWP::UserAgent;
    #use HTTP::Message::decodable;
    use XML::Simple;
    
    # Package Vars
    my $API_HOSTNAME = 'kickasstorrents.to';
    my $CLEAR_PROTO  = 'http://';
    my $SECURE_PROTO = 'https://';
    my $DEBUG        = 1;
    
    
    #opts basically just 'ssl' => 1|0
    sub new {
        my $class = shift;
        $class = ref $class || $class;
        
        my %opts;
        if (@_ > 1){
            unless (@_ % 2) {
                %opts = @_;
            }
            else {
                die "Odd number of arguments supplied to new\n";
                return;
            }
        }
        elsif ( @_ == 1 ) {
            if (ref $_[0] eq 'HASH') {
                %opts = %{ $_[0] };
            }
        }
        
        $opts{'xmlProcessor'} = XML::Simple->new();
        
        my $self = bless(\%opts, $class);
        
        return $self;
    }
    
    sub search {
        my $self = shift;
        my %opts;
        
        if (@_ > 1){
            unless (@_ % 2) {
                %opts = @_;
            }
            else {
                $self->error('Odd number of arguments supplied to search');
                return;
            }
        }
        elsif ( @_ == 1 ) {
            if (ref $_[0] eq 'HASH') {
                %opts = %{ $_[0] };
            }
            else {
                %opts = ( 'phrase' => $_[0] );
            }
        }
        else {
            $self->error('Must supply at least a search term for search()');
            return;
        }
        
        #valid categories are 'tv', 'movies', 'music'
        my $category = delete $opts{'category'};
        my $page     = delete $opts{'page'} || 1;
        my $season   = _season( delete $opts{'season'} )   || '';
        my $episode  = _episode( delete $opts{'episode'} ) || '';
        
        #Dispatcher for building the url parts for each option
        my %dispatcher = (
            allOf      => \&_allOf,
            phrase     => \&_phrase,
            anyOf      => \&_anyOf,
            noneOf     => \&_noneOf,
            user       => \&_user,
            seeds      => \&_seeds,
            age        => \&_age,
            noOfFiles  => \&_files,
            language   => \&_language,
            safe       => \&_safe,
            verified   => \&_verified,
            season     => \&_season,
            episode    => \&_episode,
            platformId => \&_platform,
        );
        
        my $uri = 'usearch/';
        
        for my $term (keys %opts) {
            next unless $dispatcher{$term};
            next unless $opts{$term};
            $uri .= ' '.$dispatcher{$term}->($opts{$term});
        }
        $uri .= $season.$episode.'/'.$page.'/?';
        $uri .= 'categories[]='.$category.'&' if $category;
        $uri .= 'field=seeders&sorder=desc&rss=1';
        
        my $rss = $self->_fetch_api($uri)
          or return [];
          
        my $data = $self->{'xmlProcessor'}->XMLin($rss);

        if ( ref $data->{'channel'}->{'item'} 
             and ref $data->{'channel'}->{'item'} eq 'HASH' ) {
            $data->{'channel'}->{'item'} = [ $data->{'channel'}->{'item'} ];
        }
        return $data->{'channel'}->{'item'} || [];
    }
    
    sub getImdbId {
        my $self = shift;
        my $url  = shift;
        
        my ($uri) = $url =~ m|([^/]+)$|;
        
        my $scrape = $self->_fetch_api($uri) || return;
        
        my ($imdbId) = $scrape =~ m|/(tt\d+)/|;
        
        return $imdbId;
    }
        
    sub error {
        my $self  = shift;
        my $error = shift;
        
        if ($error) {
            $self->{'error'} = $error;
            return $self->{'error'};
        }
        else {
            $error = $self->{'error'};
            $self->{'error'} = undef;
            return $error;
        }
        return;
    }        

    ### PRIVATES ###
    
    sub _fetch_api {
        my $self = shift;
        my $uri  = shift || return;
        my $full_url;
        
        if ($uri =~ /^http/i){
            #looks like we already have a full url
            $full_url = $uri;
        }
        else { 
            if ( $self->{'ssl'} ) {
                $full_url = $SECURE_PROTO.$API_HOSTNAME.'/'.$uri;
            }
            else {
                $full_url = $CLEAR_PROTO.$API_HOSTNAME.'/'.$uri;
            }
        }

        _debug($full_url);
        
        my $can_accept = HTTP::Message::decodable;
        my $ua = LWP::UserAgent->new();
        $ua->default_header('Accept-Encoding' => $can_accept);
        
        my $request = HTTP::Request->new(GET => $full_url);
        my $result  = $ua->request($request);
        
        my $content = $result->decoded_content(charset => 'none');
        
        if ( $result->is_success ) {
            my $content = $result->decoded_content(charset => 'none');
            return $content;
        }
        else {
            $self->error( 'API request failed: '.$result->status_line );
            return;
        }
    }
    
    sub _debug {
        return unless $DEBUG;
        my $message = shift || return;
        
        warn "$message\n";
        
        return 1;
    }
    
    ### URI Builders ###
    sub _allOf {
        my $val = shift or return;
        return ref $val ? join(' ', @{$val}) : $val;
    }
    
    sub _phrase {
        my $val = shift or return;
        return '"'.$val.'"';
    }
    
    sub _anyOf {
        my $val = shift or return;
        return ref $val ? join(' OR ', @{$val}) 
                        : join(' OR ', split(/\s+/, $val));
    }
    
    sub _noneOf {
        my $val = shift or return;
        return join (' ',
          map { "-$_" } ref($val) ? @{$val} : split(/\s+/, $val));
    }
    
    sub _user {
        my $val = shift or return;
        int($val) or die "_user needs a number\n";
        return "user:$val";
    }
    
    sub _seeds {
        my $val = shift or return;
        int($val) or die "_seeds needs a number\n";
        return "seeds:$val";
    }
    
    sub _age {
        my $val = lc(shift()) or return;
        $val =~ /^(?:hour|24h|week|month|year)$/ or die "Not a valid age\n";
        return "age:$val";
    }

    sub _files {
        my $val = shift or return;
        int($val) or die "_files needs a number\n";
        return "files:$val";
    }

    sub _language {
        my $val = shift or return;
        return "language:$val";
    }
    
    sub _safe {
        shift() ? return "is_safe:1" : return;
    } 
    
    sub _verified {
        shift() ? return "verified:1" : return;
    }
    
    sub _season {
        my $val = shift or return;
        int($val) or die "_season needs a number\n";

        #Currently the season and episode indexing on KAT is broken.  so just munge in S0XE0X
        #return "season:$val";
        my $s = sprintf('%02s', $val);
        return "S$s";
    }
    
    sub _episode {
        my $val = shift or return;
        int($val) or die "_episode needs a number\n";
        #Currently the season and episode indexing on KAT is broken.  so just munge in S0XE0X
        #return "episode:$val";
        my $e = sprintf('%02s', $val);
        return "E$e";
    }
    
    sub _platform {
        my $val = shift or return;
        int($val) or die "_platform needs a number\n";
        return "platform_id:$val";
    }


1;
