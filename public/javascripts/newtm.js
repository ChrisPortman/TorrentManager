$(document).ready(function(){
    $( "#tvPage" ).page({
        beforecreate: function( event, ui ) {
            loadTvShows();
        }
    });
    
    $( "#refresh_tv" ).click( function(){
        $.mobile.loading('show', { text: "Getting TV List", textVisible: true, theme: 'b' });
        loadTvShows() 
    } );
    
    $( "#searchButton" ).click( function(){ searchTv() } );
    $( "#settingsButton" ).click( function(){ applySettings() } );
    $( "#key" ).val(apikey());
});


function loadTvShows (shows) {
    console.log("loading TV shows");

    var key = apikey();
    $.ajax( {
        url    : '/api/tv/shows?apikey=' + key,
        success: function( data ) {
            $("#tv_list").empty();

            var shows = data.data;
            for (i in shows) {
                var show    = shows[i];
                var title   = show.title;
                var season  = show.lastSeason; 
                var episode = show.lastEpisode;

                $("#tv_list").append($('<li><a data-rel="dialog"><h2>'+title+'</h2><p>Season:'+season+' Episode:'+episode+'</p></a></li>').click(function(){ showSearch($(this) ) }));
            }
            $( "#tv_list" ).listview( "refresh" );
            $.mobile.loading('hide');
        },    
        error: function( result ) {
            var error = result.responseJSON.error;
            $.mobile.loading('hide');
            $('#theBody').pagecontainer( "change", "#notification", { role: "dialog" } );
            $('#notificationHeader').text('Failure');
            $('#notificationText').text('Error: '+error);           
        },
    } );
}

function showSearch(element) {
    var title     = element.find("h2:first").text();
    var epDetails = element.find("p:first").text();

    console.log(epDetails);
    var pattern = /(\d+)[^\d]*(\d+)$/;
    var parts   = pattern.exec(element[0].textContent);
    
    var season  = parts[1];
    var episode = parts[2];

    $('#theBody').pagecontainer( "change", "#searchPage", { role: "dialog" } );
    $('#show').val(title);
    $('#season').val(season);
    $('#episode').val(Number(episode) + 1);
}

function searchTv() {
    $.mobile.loading('show', { text: "Searching...", textVisible: true, theme: 'b' });

    var title     = $('#show').val();
    var season    = $('#season').val();
    var episode   = $('#episode').val();
    var searchStr = title;
    console.log(season+' '+episode);
    var pattern   = /^\d+$/;
    
    if ( pattern.test(season) ) {
        season    = pad(season, 2, 0);
        searchStr = searchStr+" S"+season;
    }

    if ( pattern.test(episode) ) {
        episode   = pad(episode, 2, 0);
        searchStr = searchStr+"E"+episode;
    }

    console.log(searchStr);
    var key = apikey();
    $.ajax( {
        url    : '/api/torrents/search?apikey='+key+'&search='+searchStr+'&category=tv',
        success: function( results ) {
            $('#theBody').pagecontainer( "change", "#resultPage" );
            $("#results_list").empty();
            results = results.data;
            
            for (i in results) {
                var result    = results[i];
                var tTitle    = result.title;
                var tSeeds    = result.seeds;
                var tPeers    = result.peers;
                var tSize     = result.sizeHuman;
                var tVerified = result.verified;
                var tUrl      = result.downloadURL;
                var tHash     = result.hash;
                $("#results_list").append(
                  $('<li><a data-rel="dialog"><h2>'+tTitle+'</h2><p>Size: '+tSize+' Verified: '+tVerified+' Seeds: '+tSeeds+' Peers: '+tPeers+'</p><div class="torrentUrl" style="display:none;">'+tUrl+'</div><div class="torrentHash" style="display:none;">'+tHash+'</div></a></li>').click(function(){ downloadTorrent($(this) ) }));
            }

            $( "#results_list" ).listview( "refresh" );
            $.mobile.loading('hide');
        },
        error: function( result ) {
            var error = result.responseJSON.error;
            $.mobile.loading('hide');
            $('#theBody').pagecontainer( "change", "#notification", { role: "dialog" } );
            $('#notificationHeader').text('Failure');
            $('#notificationText').text('Error: '+error);           
        },    
    } );
}

function downloadTorrent(element) {
    $.mobile.loading('show', { text: "Retrieving Torrent", textVisible: true, theme: 'b' });
    var url  = element.find("div.torrentUrl:first").text();
    var hash = element.find("div.torrentHash:first").text();
    console.log(url);
    console.log(hash);

    var key = apikey();
    $.ajax( {
        url    : '/api/torrents/download?apikey='+key+'&category=tv&url='+url+'&hash='+hash,
        success: function( result ) {
            $.mobile.loading('hide');
            $('#theBody').pagecontainer( "change", "#notification", { role: "dialog" } );
            $('#notificationHeader').text('Success');
            $('#notificationText').text('Torrent Downloaded');           
        },
        error: function( result ) {
            var error = result.responseJSON.error;
            $.mobile.loading('hide');
            $('#theBody').pagecontainer( "change", "#notification", { role: "dialog" } );
            $('#notificationHeader').text('Failure');
            $('#notificationText').text('Error: '+error);           
        },    
    } );
}

function applySettings() {
    $.mobile.loading('show', { text: "Applying Settings", textVisible: true, theme: 'b' });

    var key = $('#key').val();
    $.ajax( {
        url    : '/api/test?apikey='+key,
        success: function( result ) {
            apikey(key);
            $.mobile.loading('hide');
            $('#theBody').pagecontainer( "change", "#notification", { role: "dialog" } );
            $('#notificationHeader').text('Success');
            $('#notificationText').text('Settings Applied');       
        },
        error: function( result ) {
            var error = result.responseJSON.error;
            $.mobile.loading('hide');
            $('#theBody').pagecontainer( "change", "#notification", { role: "dialog" } );
            $('#notificationHeader').text('Failure');
            $('#notificationText').text('Error: '+error);           
        },    
    } );
}

function apikey(key) {
    if (key) {
        localStorage.setItem('apikey', key);
    }
    else {
        key = localStorage.getItem('apikey');
    }
    
    if (key) {
        return key;
    }
    else {
        return '';
    }
}

function requestParam(name){
    if(name=(new RegExp('[?&]'+encodeURIComponent(name)+'=([^&]*)')).exec(location.search))
        return decodeURIComponent(name[1]);
}

function pad(n, width, z) {
    z = z || '0';
    n = n + '';
    return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
}
