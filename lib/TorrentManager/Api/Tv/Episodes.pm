package TorrentManager::Api::Tv::Episodes;

our $VERSION = '0.1';

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Models::Tv qw( getEpisodes );

prepare_serializer_for_format;
prefix '/api/tv/episodes';

get '/' => sub {
    my $dir    = config->{'showDir'};
    my $show   = params->{'show'};
    my $season = params->{'season'};
    $dir =~ s|/$||;

    my ($success, $data) = getEpisodes($dir, $show, $season);
    
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
