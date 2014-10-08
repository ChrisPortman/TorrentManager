package TorrentManager;

use Dancer ':syntax';
use Dancer::Plugin::REST;
use TorrentManager::Api;
use Data::Dumper;

our $VERSION = '0.1';

prepare_serializer_for_format;

prefix '/';

hook 'before' => sub {
    my $config = config->{imdbIds};
    
    unless (config->{'apikey'}) {
        die "APIKEY not set in the configuration file for this environment.\n";
    }
    
    unless ( params->{'apikey'} and params->{'apikey'} eq config->{'apikey'} ) {
        error 'NO API KEY PROVIDED';
        request->path_info('/noapikey');
    }
};

get '/' => sub {
    template 'index';
};

any '/noapikey' => sub {
    status 401;
    { 'error' => 'API Key not provided or is incorrect' };    
};

true;
