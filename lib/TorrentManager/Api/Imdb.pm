package TorrentManager::Api::Imdb;

use Dancer ':syntax';
use Dancer::Plugin::REST;

our $VERSION = '0.1';

prefix '/api/imdb';

get '/getid' => sub {
    my $success = 0;
    my $data    = 'Hash not found';
    
    my $torrentHash = params->{'hash'};
    
    if ( config->{'imdbIds'}->{$torrentHash} ) {
        $data = config->{'imdbIds'}->{$torrentHash};
        $success = 1;
    }

    if ($success) {
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
