package TorrentManager::Models::Deluge;

use strict;
use Data::Dumper;
use Exporter 'import';

our @EXPORT_OK = qw( showTorrents );

sub showTorrents {
    my $config = shift;
    
    my $cmd = 'deluge-console -c '.$config.' info';
    
    my $torrentInfo = `$cmd`;
    $torrentInfo or return (1,[]);
    
    my @torrents = split(/\n\s*\n/, $torrentInfo);
    
    my @downloading;
    my @queued;
    my @other;
    
    for my $torrent (@torrents) {
        my %properties = map { my ($key, $val) = $_ =~ /^([^:]+)\s*:\s*(.+)$/;
                               $key => $val 
                         }
                         grep { $_ =~ /^([^:]+):(.+)$/ }
                         split(/\n/, $torrent);
        
        #clean up some properties
        $properties{'Size'} and
        ($properties{'Size'}) = $properties{'Size'}  =~ m|/(\d+\.\d*\s\w+)\sRatio|;

        if ( $properties{'State'} and $properties{'State'} =~ /Downloading/i ) { 
            my ($down, $up) = $properties{'State'} =~ m|Down\sSpeed:\s(\d+\.\d*\s\w+/s)\sUp\sSpeed:\s(\d+\.\d*\s\w+/s)|;
            $properties{'Speed'} = 'Down: '.$down.', Up: '.$up;
        }
        
        $properties{'State'} and
        ($properties{'State'}) = $properties{'State'} =~ /^(\w+)/;
        
        $properties{'Progress'} and
        ($properties{'Progress'}) = $properties{'Progress'}  =~ m|(\d+\.\d*%)\s|;
        
        my $state = $properties{'state'};
        
        if ($state) {
            if ($state eq 'Downloading') {
                push @downloading, \%properties;
            }
            elsif ($state eq 'Queued') {
                push @queued, \%properties;
            }
            else {
                push @other, \%properties;
            }
        }
        else {
            push @other, \%properties;
        }
    }
    
    my @data = ( @downloading, @queued, @other );

    return (1, \@data) 
}
