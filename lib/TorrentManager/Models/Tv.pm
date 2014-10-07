package TorrentManager::Models::Tv;

use strict;
use Exporter 'import';

our @EXPORT_OK = qw( getShows getSeasons getEpisodes);

sub getShows {
    my $dir = shift;
    my $dh;
    
    unless ( $dir and -d $dir ) {
        return ( undef, "Server not configured with correct Shows directory" );
        
    }
    
    unless ( opendir($dh, $dir) ) {
        return ( undef, "Server could not open the Shows directory" );
    }        
    
    my @shows;
    
    for my $show ( grep { -d $dir.'/'.$_ and $_ !~ /^\.\.?$/ } readdir($dh) ) {
    #for my $show (  readdir($dh) ) {
        push @shows, { 'title' => $show };
    }

    return (1, \@shows);
}

sub getSeasons {
    my $dir  = shift;
    my $show = shift;
    my $dh;
    
    $dir = $dir.'/'.$show;

    unless ( $show ) {
        return (undef, "Must supply a shows parameter." );
    }

    unless ( $dir and -d $dir ) {
        return (undef, "A directory for the requested show does not exist." );
    }
    
    if ( opendir($dh, $dir) ) {
    
        my @seasons;
        
        for my $season ( grep { -d $dir.'/'.$_ and $_ =~ /^Season\s\d+$/i } readdir($dh) ) {
            my ($seasonNo) = $season =~ /(\d+)$/;
            push @seasons, { 'season' => $seasonNo, 'folder' => $season };
        }
        
        return ( 1, \@seasons );
    }
    else {
        return (undef, "Server could not open the shows season directory" );
    }
}

sub getEpisodes {
    my $dir    = shift;
    my $show   = shift;
    my $season = shift;
    my $dh;
    
    unless ( $show ) {
        return( undef, "Must supply a shows parameter." );
    }
    unless ( $season ) {
        return( undef, "Must supply a season parameter." );
    }
    
    $season = 'Season '.$season if $season =~ /^\d+$/; #Accept the folder as the arg or just the season number.
    $dir = $dir.'/'.$show.'/'.$season;
    
    unless ( $dir and -d $dir ) {
        return( undef, "A directory for the requested show ans season does not exist." );
    }
    
    if ( opendir($dh, $dir) ) {
        my @episodes;
        
        for my $episode ( grep { -f $dir.'/'.$_ and $_ =~ /^Episode\s(?:\d+\s?x\s?\d+)(?:\s?-\s?\d+\s?x\s?\d+)?\..+$/i } readdir($dh) ) {
            my ($episodeNo) = $episode =~ /(\d+)[^\d]*$/;
            push @episodes, { 'episode' => $episodeNo, 'file' => $episode };
        }
        
        return (1, \@episodes);

    }
    else {
        return(undef, "Server could not open the shows season directory" );
    }        
}


1;
