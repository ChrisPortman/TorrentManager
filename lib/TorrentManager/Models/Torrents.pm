package TorrentManager::Models::Torrents;

use strict;
use WebService::KickassTorrents;
use Time::Piece;
use LWP::UserAgent;
use Exporter 'import';
use Dancer ':syntax';
use Data::Dumper;

our @EXPORT_OK = qw( search download getImdbId );

sub search {
    my $search   = shift;
    my $category = shift;
    my $season   = shift;
    my $episode  = shift;
    my $verified = shift;
    my $page     = shift || 1;
    
    $search
      or return ( undef, "Search not probided for search." );
    
    $category and $category =~ /^(?:tv|movies)$/ or $category = undef;
    $season   and $season   =~ /^\d+$/           or $season   = undef;
    $episode  and $episode  =~ /^\d+$/           or $episode  = undef;
    
    my $torrentSearch = WebService::KickassTorrents->new();
    my $results = $torrentSearch->search(
        'phrase'   => $search,  
        'category' => $category,
        #'language' => 'english',
        'verified' => $verified,
        'season'   => $season,
        'episode'  => $episode,
        'page'     => $page,
    )
      or return ( undef, 'Searching Kickass Torrents failed: '.$torrentSearch->error() );
   
    debug Dumper($results);
 
    #Clean up the results a little
    for my $torrent (@{$results}) {
        my $pubDate  = $torrent->{'pubDate'};
        my $pubEpoch = Time::Piece->strptime($pubDate, "%a, %d %b %Y %H:%M:%S %z");
        
        $torrent->{'pubEpoch'}    = $pubEpoch->epoch;
        $torrent->{'downloadURL'} = $torrent->{'enclosure'}->{'url'};
        $torrent->{'size'}        = delete $torrent->{'torrent:contentLength'};
        $torrent->{'seeds'}       = delete $torrent->{'torrent:seeds'};
        $torrent->{'peers'}       = delete $torrent->{'torrent:peers'};
        $torrent->{'verified'}    = delete $torrent->{'torrent:verified'};
        $torrent->{'hash'}        = delete $torrent->{'torrent:infoHash'};
        $torrent->{'sizeHuman'}   = convertSize($torrent->{'size'});
        #$torrent->{'imdbId'}     = $torrentSearch->getImdbId($torrent->{'link'});
        
        delete $torrent->{'enclosure'};
        delete $torrent->{'guid'};
        delete $torrent->{'description'};
        delete $torrent->{'torrentLink'};
    }
    
    #$results = [ sort {$b->{'pubEpoch'} <=> $a->{'pubEpoch'}} @{$results} ];
    
    return (1, $results);
}

sub searchMovies {
    
}

sub download {
    my $destFile    = shift;
    my $torrentUrl  = shift; #download url
    
    my $can_accept = HTTP::Message::decodable;
    my $ua = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0 },
    );
    $ua->default_header('Accept-Encoding' => $can_accept);
    
    my $request = HTTP::Request->new(GET => $torrentUrl);
    my $result  = $ua->request($request);

    unless ( $result->is_success ) {
        return(undef, 'Failed to get torrent file: '.$result->status_line );
    }
    
    my $content = $result->decoded_content(charset => 'none');
    
    open (my $torFh, '>', $destFile)
      or return ( undef, 'Unable to create torrent file '.$destFile.": $!");
    
    binmode($torFh);
    print $torFh $content;
    
    close $torFh;
    
    return (1, 'Torrent retrieved');
}

sub getImdbId {
    my $infoUrl = shift;
    my $kickass = WebService::KickassTorrents->new();
    my $imdb = $kickass->getImdbId($infoUrl);
    
    return $imdb;
}

sub convertSize {
    my $bytes = shift || return;

    if($bytes > 1073741824){ 
       $bytes = ( sprintf( "%0.2f", $bytes/1073741824 )). " GB";                   
    }
    elsif ($bytes > 1048576){       
       $bytes = ( sprintf( "%0.2f", $bytes/1048576 )). " MB"; 
    }
    elsif ($bytes > 1024){
       $bytes = ( sprintf( "%0.2f", $bytes/1024 )). " kB"; 
    }
    else{ 
       $bytes = sprintf( "%0.2f", $bytes ). " B";
    } 
    
    return $bytes;
}
