"use strict"

###
	Controllers
###

app = angular.module('NetTalk.controllers')

app.controller 'AppCtrl', (Animation) ->
	Animation.start()

app.controller 'SplashCtrl', ($scope, $window, $location, ctrlSocket, aircraftControls) ->
	$scope.controlChallengeWasSuccessful = false
	$scope.onSubmit = ->
		ctrlSocket.emit 'acquire_control_challenge',
			code: $scope.userEnteredCode
	ctrlSocket.on 'acquire_control_challenge_response', (data) ->
		$scope.controlChallengeWasSuccessful = data.success
		aircraftControls.code = data.code
		aircraftControls.position = data.position
		aircraftControls.heading = data.heading
		aircraftControls.speed = data.speed
		if data.success is true
			$location.path "/controls"

app.controller 'UserControlsCtrl', ($scope, $timeout, $window, $location, $log, ctrlSocket, aircraftControls) ->
	$location.path("/splash") unless aircraftControls.position?

	arrowRotation = 0
	hasNewDataToBroadcast = false

	$scope.$watch 'rotationValue', (newAngle) ->
		if newAngle?
			hasNewDataToBroadcast = true
			arrowRotation = newAngle

	$scope.$on '$viewContentLoaded', ->
		if aircraftControls.position?
			updateAircraftPosition() unless positionUpdateTimer?
			broadcastUserState() unless broadcastTimer?

	positionUpdateTimer = null
	updateAircraftPosition = ->
		positionUpdateTimer = $timeout updateAircraftPosition, 1000 / 60
		if hasNewDataToBroadcast is false or
		isNaN(arrowRotation) is true or
		angular.isArray(aircraftControls.position) is false or
		isNaN(aircraftControls.position[0]) is true
			return
		curLatLng = new google.maps.LatLng aircraftControls.position[0], aircraftControls.position[1]
		nextLatLng = google.maps.geometry.spherical.computeOffset(
			curLatLng,
			aircraftControls.speed,
			arrowRotation * 180 / Math.PI
		)
		aircraftControls.position = [nextLatLng.lat(), nextLatLng.lng()]
		aircraftControls.heading = arrowRotation

	broadcastTimer = null
	broadcastUserState = ->
		broadcastTimer = $timeout broadcastUserState, 500
		return unless hasNewDataToBroadcast
		ctrlData =
			heading: aircraftControls.heading
			code: aircraftControls.code
			position: aircraftControls.position

		ctrlSocket.emit 'user_ctrl', ctrlData
		hasNewDataToBroadcast = false
		$log.info "broadcasting state", ctrlData.position
	@

app.controller 'MapCtrl', ($scope, $window, mapSocket) ->
	$scope.aircrafts = {}

	$scope.onMapLoad = ->
		google.maps.event.addListener $scope.map, "rightclick", (e) ->
			console.log "rightclick"
			new google.maps.Marker
				map: $scope.map
				position: e.latLng
			console.log "pos", e.latLng.toString()

	mapSocket.on 'aircraftData', (aircraftData) ->
		for code, aircraft of aircraftData
			$scope.aircrafts[code] =
				code: code
				lat: aircraft.position[0]
				lng: aircraft.position[1]
				heading: aircraft.heading
		null