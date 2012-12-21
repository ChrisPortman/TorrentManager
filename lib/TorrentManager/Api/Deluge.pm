package TorrentManager::Api::Deluge;

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Models::Deluge qw( showTorrents );
use Data::Dumper;

our $VERSION = '0.1';

prefix '/api/deluge';

get '/show' => sub {
    my $delugeConfig = config->{'delugeConfig'};
    my $success;
    my $data;
    
    if ($delugeConfig) {
        ($success, $data) = showTorrents($delugeConfig);
    }
    else {
        $data = 'No config location for Deluge configured';
    }
    
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
