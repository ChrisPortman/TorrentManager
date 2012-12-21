package TorrentManager::Api;

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Api::Tv::Shows;
use TorrentManager::Api::Tv::Seasons;
use TorrentManager::Api::Tv::Episodes;
use TorrentManager::Api::Torrents;
use TorrentManager::Api::Deluge;

our $VERSION = '0.1';

set serializer  => 'JSON';

prefix '/api';

get '/' => sub {
    template 'index';
};

any '/test' => sub {    
    status_ok(
        {
            success => 1,
            data    => 'Test successful',
        }
    );
};

true;
