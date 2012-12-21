package TorrentManager::Api::Tv::Seasons;

our $VERSION = '0.1';

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Models::Tv qw( getSeasons );

prepare_serializer_for_format;
prefix '/api/tv/seasons';

get '/' => sub {
    my $dir  = config->{'showDir'};
    my $show = params->{'show'};
    $dir =~ s|/$||;
    
    my ($success, $data) = getSeasons($dir, $show);
    
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
