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
		$location.path "/controls"

app.controller 'UserControlsCtrl', ($scope, $timeout, $window, $location, $log, ctrlSocket, aircraftControls) ->
	$location.path("/splash") unless aircraftControls.position?

	lastActivityTimestamp = new Date().getTime()
	arrowRotation = null
	lastActivityTimestamp = null
	hasNewDataToBroadcast = false

	$scope.$on 'rotate_angle_changed', (event, newAngle) ->
		event.stopPropagation()
		lastActivityTimestamp = new Date().getTime()
		hasNewDataToBroadcast = true
		arrowRotation = newAngle

	$scope.$on '$viewContentLoaded', ->
		updateAircraftPosition() unless positionUpdateTimer?
		broadcastUserState() unless broadcastTimer?

	positionUpdateTimer = null
	updateAircraftPosition = ->
		positionUpdateTimer = $timeout updateAircraftPosition, 1000 / 60
		return unless hasNewDataToBroadcast
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

app.controller 'MapCtrl', ($scope, $timeout, $window, mapSocket, ctrlSocket) ->
	#SPEED = 40
	currentHeading = 0 # Due North
	peerDisconnected = true
	planeSprite = $window.jQuery('#plane')
	serverAircraftData = new Object()
	aircraftSprites = new Object()
	myAircraft = null
	mapLoaded = false

	$scope.onMapLoad = ->
		#startPositionBroadcast()
		mapLoaded = true
		drawAircrafts(serverAircraftData)
		google.maps.event.addListener $scope.map, "rightclick", (e) ->
			console.log "rightclick"
			new google.maps.Marker
				map: $scope.map
				position: e.latLng
			console.log "pos", e.latLng.toString()

	onPlanePositionChanged = (code, data) ->
		plane = getPlaneSpriteFor(data)
		#if $scope.map?
			#new google.maps.Marker
				#map: $scope.map
				#position: new google.maps.LatLng data.position...
		animateSinglePlane(plane, data)

	drawAircrafts =  (aircraftData) ->
		serverAircraftData = aircraftData
		# TODO: make the user choose this
		if mapLoaded
			onPlanePositionChanged(code, aircraft) for code, aircraft of serverAircraftData
	mapSocket.on 'aircraftData', drawAircrafts

	onPeerDisconnected = (data) ->
		peerDisconnected = true

	ctrlSocket.on 'peer_disconnected', onPeerDisconnected
	ctrlSocket.on 'peer_inactive', onPeerDisconnected

	followAircraft = (code) ->
		if myAircraft?
			planeSprite.hide 'fade'
			oldPlaneSprite = getPlaneSpriteFor myAircraft
			oldPlaneSprite.marker.setMap $scope.map
		sprite = aircraftSprites[code]
		sprite.marker.getMap().panTo sprite.marker.getPosition()
		sprite.marker.setMap null
		planeSprite.show 'fade'
		myAircraft = serverAircraftData[code]

	getPlaneSpriteFor = (aircraftData) ->
		code = aircraftData.code
		sprite = aircraftSprites[code]
		return sprite if sprite?
		sprite =
			code: code
			marker: new google.maps.Marker
				map: $scope.map
				position: new google.maps.LatLng(aircraftData.position[0], aircraftData.position[1])
				title: "F15 Strike Eagle"
		infoWindow = new google.maps.InfoWindow
			content: "<p>Code: #{code}</p>"
			maxWidth: 200
		infoWindow.open $scope.map, sprite.marker
		google.maps.event.addListener sprite.marker, "dblclick", ->
			followAircraft code
		aircraftSprites[code] = sprite

	tweenHeading = (plane, aircraftData, duration) ->
		return unless (myAircraft? and aircraftData.code is myAircraft.code)
		plane.tweens.heading?.stop()
		current =
			heading: currentHeading
		next =
			heading: aircraftData.heading

		if (Math.abs(current.heading - next.heading) > Math.PI)
			current.heading += 2 * (if current.heading < 0 then Math.PI else -Math.PI)
		plane.tweens.heading = new TWEEN.Tween(current)
			.to(next, duration)
			.onUpdate(->
				currentHeading = @heading
				planeSprite.css
					transform: "rotate(#{@heading}rad)"
			)
			.start()

	tweenPosition = (plane, aircraftData, duration) ->
		plane.tweens.position?.stop()
		currentPos = plane.marker.getPosition()
		current =
			lat: currentPos.lat()
			lng: currentPos.lng()
		next =
			lat: aircraftData.position[0]
			lng: aircraftData.position[1]
		plane.tweens.position = new TWEEN.Tween(current)
			.to(next, duration)
			.onUpdate(->
				plane.marker.setPosition new google.maps.LatLng(@lat, @lng)
				if (myAircraft? and aircraftData.code is myAircraft.code)
					$scope.map.panTo plane.marker.getPosition()
			)
			.start()

	animateSinglePlane = (plane, planeServerData) ->
		plane.tweens ?= new Object
		tweenHeading(plane, planeServerData, 100)
		tweenPosition(plane, planeServerData, 2000)

