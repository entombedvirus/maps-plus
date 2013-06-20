"use strict"

###
	Controllers
###

app = angular.module('NetTalk.controllers')

app.controller 'SocketCtrl', ($scope, Socket) ->
	Socket.on "pong", (data) ->
		$scope.response = data.data

	$scope.ping = ->
		Socket.emit("ping", {})

app.controller 'MapCtrl', ($scope) ->
	$scope.onMapLoad = ->
		console.log "map loaded"
		new google.maps.event.addListener $scope.map, "rightclick", dropMarker
		new google.maps.event.addListener $scope.map, "center_changed", logCenter

	dropMarker = (e) ->
		console.log "dropMarker", e
		new google.maps.Marker
			map: $scope.map
			position: e.latLng

	logCenter = ->
		console.log("map center is now", $scope.map.getCenter().toString())

