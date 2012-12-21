package TorrentManager::Api::Tv::Shows;

our $VERSION = '0.1';

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Models::Tv qw( getShows getSeasons getEpisodes );

prepare_serializer_for_format;
prefix '/api/tv/shows';

get '/' => sub {
    debug 'Firing the Tv Shows API';
    
    my $success;
    my $data;
    my $dir = config->{'showDir'};
    $dir =~ s|/$||;
    
    debug 'Folder containing shows is configured as '.($dir || 'undefined');
    
    ($success, $data) = getShows($dir);
    
    debug 'Success is '.($success || 'undefined');
    debug 'Data is '.($data || 'undefined');
    $success
      or return status_bad_request( $data );
    
    my @shows = sort { $a->{'title'} cmp $b->{'title'} } @{$data};
    
    for my $show ( @shows ) {
        #Get the seasons for the show then get the last one.
        ($success, $data) = getSeasons($dir, $show->{'title'});
        $success or next;
        
        my @seasons = sort { $b->{'season'} <=> $a->{'season'} } @{$data};
        
        $show->{'lastSeason'} = $seasons[0]->{'season'};
        
        #Get the episodes for the last season and store the last one.
        ($success, $data) = getEpisodes($dir, $show->{'title'}, $show->{'lastSeason'});
        $success or next;
        
        my @episodes = sort { $b->{'episode'} <=> $a->{'episode'} } @{$data};
        
        $show->{'lastEpisode'} = $episodes[0]->{'episode'};
    }
    
    if ( $success ) {
        status_ok(
            {
                success => 1,
                data    => \@shows,
            }
        );
    }
    else {
        status_bad_request( $data );
    }
};

true;
