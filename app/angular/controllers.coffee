"use strict"

###
	Controllers
###

app = angular.module('NetTalk.controllers')

app.controller 'AppCtrl', (Animation) ->
	Animation.start()

app.controller 'SocketCtrl', ($scope, Socket) ->
	$scope.response = "waiting..."
	Socket.chat.on "pong", (data) ->
		console.log "got pong msg", data
		$scope.response = data.data

	$scope.ping = ->
		Socket.chat.emit("ping", {})

app.controller 'MapCtrl', ($scope, $timeout, Socket) ->
	currentBounds = null
	lastBroadcastData = null
	rectangles = {}
	marker = null

	$scope.onMapLoad = ->
		console.log "map loaded"

		new google.maps.event.addListener $scope.map, "rightclick", dropMarker
		new google.maps.event.addListener $scope.map, "bounds_changed", onMapBoundsChanged

		$timeout ->
			console.log "delayed exec", $scope.map.getBounds().toString()
			onMapBoundsChanged()
			broadcastState()
		,
			1000

		Socket.map.on 'viewport_broadcast', onViewportBroadcastFromServer
		Socket.map.on 'peer_disconnected', onPeerDisconnected

	dropMarker = (e) ->
		console.log "dropMarker", e
		new google.maps.Marker
			map: $scope.map
			position: e.latLng

	broadcastState = =>
		$timeout broadcastState, 1000, false
		return unless currentBounds?
		return if lastBroadcastData? and lastBroadcastData.equals currentBounds
		viewport = currentBounds.toUrlValue()
		Socket.map.emit 'viewport_changed', viewport
		lastBroadcastData = currentBounds

	# It's importang to keep event handlers cheap so as to not go over the 16ms or
	# so budget to ensure 60fps
	onMapBoundsChanged= ->
		currentBounds = $scope.map.getBounds()

	onViewportBroadcastFromServer = (data) ->
		viewportString = data.viewport
		console.log "got viewport broadcast", viewportString
		rect = getRectangleFor data.client_id
		parts = (parseFloat(num) for num in viewportString.split(',', 4))
		sw = new google.maps.LatLng(parts[0], parts[1])
		ne = new google.maps.LatLng(parts[2], parts[3])
		peerBounds = new google.maps.LatLngBounds(sw, ne)

		# dont render peer's rect if ours is completely encompassed by it
		if (!currentBounds? or (peerBounds.contains(currentBounds.getNorthEast()) and peerBounds.contains(currentBounds.getSouthWest())))
			console.log "skipping rendering #{data.client_id}'s viewport because it is too large"
		else
			tweenRect(rect, parts...)

	onPeerDisconnected = (data) ->
		rect = rectangles[data.client_id]
		rect?.setMap null
		delete rectangles[data.client_id]
	
	getRectangleFor = (client_id) ->
		rectangles[client_id] ?= new google.maps.Rectangle
			map: $scope.map
			strokeColor: "#222"
			strokeOpacity: 0.6
	
	tweenRect = (rect, lo_lat, lo_lng, hi_lat, hi_lng) ->
		return unless rect?
		rectBounds = rect.getBounds() || currentBounds
		curPos =
			lo_lat: rectBounds.getSouthWest().lat()
			lo_lng: rectBounds.getSouthWest().lng()
			hi_lat: rectBounds.getNorthEast().lat()
			hi_lng: rectBounds.getNorthEast().lng()
		targetPos =
			lo_lat: lo_lat
			lo_lng: lo_lng
			hi_lat: hi_lat
			hi_lng: hi_lng
		
		tween = new TWEEN.Tween(curPos).to(targetPos, 600)
		tween.onUpdate ->
			sw = new google.maps.LatLng(@lo_lat, @lo_lng)
			ne = new google.maps.LatLng(@hi_lat, @hi_lng)
			rect.setBounds new google.maps.LatLngBounds(sw, ne)
		#tween.onComplete ->
			#sw = new google.maps.LatLng(targetPos.lo_lat, targetPos.lo_lng)
			#ne = new google.maps.LatLng(targetPos.hi_lat, targetPos.hi_lng)
			#rect.setBounds new google.maps.LatLngBounds(sw, ne)
		tween.start()
