var server = 'https://oose-survival.herokuapp.com'

var map = L.map('map', {
    center: [39.3283322, -76.6195599],
    zoom: 11
});
L.tileLayer('https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png', {
	maxZoom: 18
}).addTo(map);
L.tileLayer(server + '/v1/heatmap/{x}-{y}-{z}.png', {
	maxZoom: 12
}).addTo(map);
myControl = L.control({position: 'bottomleft'});
myControl.onAdd = function(map) {
	this._div = L.DomUtil.create('div', 'myControl');
	this._div.innerHTML =
		'<form>' +
		'<input type="text" placeholder="From" id="from"/>' +
		'<input type="text" placeholder="To" id="to" />' +
		'<input type="submit" value="Route" />' +
		'</form>';
	return this._div;
}
myControl.addTo(map);

$('input').each(function() {
	L.DomEvent.disableClickPropagation(this);
});

var mqKey = 'afbtgu28aAJW4kgGbc8yarMCZ3LdWWbh'

function mqShape(sessionId, callback) {
	if (!sessionId) { return; }
	$.getJSON('https://open.mapquestapi.com/directions/v2/routeshape', {
		key: mqKey,
		sessionId: sessionId,
		fullShape: true
	}, function(data) {
		callback(data.route.shape.shapePoints)
	});
}

function mqRoute(from, to, mustAvoid, tryAvoid, callback) {
	var request = {
		key: mqKey,
		from: from,
		to: to,
		routeType: 'pedestrian'
	};
	if (mustAvoid) { request.mustAvoidLinkIds = mustAvoid.join(','); }
	if (tryAvoid) { request.tryAvoidLinkIds = tryAvoid.join(','); }
	$.getJSON('https://open.mapquestapi.com/directions/v2/route', request, function(data) {
		mqShape(data.route.sessionId, callback);
	});
}

function avoid(from, to, callback) {
	$.getJSON(server + '/v1/avoidLinkIds', {
		fromLat: from[0],
		toLat: to[0],
		fromLng: from[1],
		toLng: to[1]
	}, callback);
}

function toCoords(shape) {
	var coords = [];
	for (var i = 0; i < shape.length; i += 2) {
		coords.push([shape[i], shape[i + 1]]);
	}
	return coords;
}

var fastestRoute, middleRoute, safestRoute;

function route(from, to, push) {
	if (fastestRoute) { fastestRoute.remove(); }
	if (middleRoute) { middleRoute.remove(); }
	if (safestRoute) { safestRoute.remove(); }
	mqRoute(from, to, null, null, function(shape) {
		if (!shape || shape.length < 2) {
			alert('MapQuest failed!');
			return;
		}
		var coords = toCoords(shape);
		var first = coords[0];
		var last = coords[coords.length - 1];
		if (push) {
			history.pushState(null, null, '?' + $.param({
				from: from,
				to: to,
				fromLat: first[0],
				toLat: last[0],
				fromLng: first[1],
				toLng: last[1]
			}));
		}
		fastestRoute = L.polyline(coords, {color: 'red', weight: 5, opacity: 0.5}).addTo(map);
		map.fitBounds(fastestRoute.getBounds());
		avoid(first, last, function(linkIds) {
			mqRoute(from, to, null, linkIds.red, function(shape) {
				middleRoute = L.polyline(toCoords(shape), {color: 'yellow', weight: 5, opacity: 0.5}).addTo(map);
			});
			mqRoute(from, to, linkIds.red, linkIds.yellow, function(shape) {
				safestRoute = L.polyline(toCoords(shape), {color: 'green', weight: 5, opacity: 0.5}).addTo(map);
			});
		});
	});
}

$('form').submit(function() {
	var from = $('#from').val();
	var to = $('#to').val();
	if (!from || !to) {
		alert('Please enter origination and destination.');
		return false;
	}
	route(from, to, true);
	return false;
});

var search = location.search.substring(1);
query = JSON.parse('{"' + decodeURI(search).replace(/"/g, '\\"').replace(/&/g, '","').replace(/=/g,'":"') + '"}');
if (query.from && query.to && query.fromLat && query.toLat && query.fromLng && query.toLng) {
	$('#from').val(query.from);
	$('#to').val(query.to);
	route(query.fromLat + ',' + query.fromLng, query.toLat + ',' + query.toLng, false);
}