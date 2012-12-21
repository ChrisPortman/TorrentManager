package TorrentManager::Api::Torrents;

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Models::Torrents qw( search download getImdbId );

our $VERSION = '0.1';

prefix '/api/torrents';

get '/' => sub {
    template 'index';
};

get '/search' => sub {
    my $success;
    my $data;
    
    my $search   = params->{'search'};
    my $category = params->{'category'};
    my $season   = params->{'season'};
    my $episode  = params->{'episode'};
    my $verified = params->{'verified'};
    my $page     = params->{'page'} || 1;
    
    #assume category is tv if its not set but there is a season.
    $category ||= 'tv' if $season;
    $category = lc($category) if $category;

    $search
      or return status_bad_request( "Search not probided for search." );

    debug 'Search is '  .($search   || 'UNDEFINED');
    debug 'Category is '.($category || 'UNDEFINED');
    debug 'Season is '  .($season   || 'UNDEFINED');
    debug 'Episode is ' .($episode  || 'UNDEFINED');
    debug 'Verified is '.($verified || 'UNDEFINED');
    
    ($success, $data) = search( $search, $category, $season, $episode, $verified, $page);
    
    if ( $success ) {
        status_ok(
            {
                success => 1,
                data    => $data,
            }
        );
    }
    else {
        status_bad_request( $data );
    }
};

any ['get', 'post'] => '/download' => sub {
    my $category    = lc(params->{'category'}) || 'other'; #tv|movies|other
    my $title       = params->{'title'}    || params->{'hash'} || 'unnamed';
    my $torrentUrl  = params->{'url'};      #url
    my $torrentHash = params->{'hash'};
    my $torrentInfo = params->{'info'};    #info url
    
    my $success;
    my $data;
    my $imdbId;

    $torrentUrl
      or return status_bad_request( "No torrent URL supplied." );

    if ($torrentInfo and $torrentHash) {
        $imdbId = getImdbId($torrentInfo);    
        debug 'IMDB ID is '.($imdbId || 'not available');
        
        if ($imdbId) {
            unless ( config->{'imdbIds'} ) {
                config->{'imdbIds'} = {};
            }
            config->{'imdbIds'}->{$torrentHash} = $imdbId;
        }
    }
    
    my %torrentFolders = (
        'tv'     => config->{'tvTorrentWatch'}     || undef,
        'movies' => config->{'moviesTorrentWatch'} || undef,
        'other'  => config->{'otherTorrentWatch'}  || undef,
    );
   
    #Only use top level categories for filing away downloaded torrents. 
    $category =~ s/^(\w+).*$/$1/; 
    $torrentFolders{$category}
      or return status_bad_request( 'The location for '.$category.' torrents is not set');
    
    $torrentFolders{$category} =~ s|/$||;
    my $destFile = $torrentFolders{$category}.'/'.$title.'.torrent';
    
    ($success, $data) = download($destFile, $torrentUrl);
    
    if ( $success ) {
        status_ok(
            {
                success => 1,
                data    => $data,
            }
        );
    }
    else {
        status_bad_request( $data );
    }
};

true;
