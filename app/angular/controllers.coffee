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

app.controller 'UserControlsCtrl', ($scope, $timeout, $window, ctrlSocket, aircraftControls) ->
	curX = 0
	curY = 0
	arrow = angular.element document.getElementById('arrow')
	arrowX = arrow.offset().left
	arrowY = arrow.offset().top
	centerX = arrowX + (arrow.width() / 2)
	centerY = arrowY +  (arrow.height() / 2)
	arrowRotation = 0
	lastActivityTimestamp = new Date().getTime()
	paused = false

	timer = null
	do startIdleTimer = ->
		idleTime = (new Date()).getTime() - lastActivityTimestamp
		if idleTime > 5000
			timer = null
			paused = true
			ctrlSocket.emit 'peer_inactive'
		else
			timer = setTimeout startIdleTimer, 5000
			resume() if paused
	
	$scope.onUserTouchMove = (e) ->
		lastActivityTimestamp = (new Date()).getTime()
		startIdleTimer() unless timer?
		e = e.touches?[0] ? e
		curX = e.originalEvent.pageX
		curY = e.originalEvent.pageY

	do animateArrow = ->
		newAngle = aircraftControls.heading
		# ensure a smooth animation when the angles wrap around
		diff = Math.abs(newAngle - arrowRotation)
		if diff > Math.PI
			if newAngle > 0
				arrowRotation += 2 * Math.PI
			else
				arrowRotation += -2 * Math.PI
		tween = new TWEEN.Tween({angle: arrowRotation}).to({angle: newAngle}, 25)
		tween.onUpdate ->
			arrow.css
				transform: "rotate(#{@angle}rad)"
		tween.onComplete ->
			arrowRotation = newAngle
			animateArrow()
		tween.start()

	do updateAircraftPosition = ->
		$timeout updateAircraftPosition, 1000 / 60
		return if paused
		curLatLng = new google.maps.LatLng aircraftControls.position...
		nextLatLng = google.maps.geometry.spherical.computeOffset(
			curLatLng,
			aircraftControls.speed,
			aircraftControls.heading * 180 / Math.PI
		)
		aircraftControls.position = [nextLatLng.lat(), nextLatLng.lng()]
		aircraftControls.heading = Math.atan2(curY - centerY, curX - centerX) + Math.PI/2

	do broadcastUserState = ->
		$timeout broadcastUserState, 500
		ctrlData =
			heading: aircraftControls.heading
			code: aircraftControls.code
			position: aircraftControls.position

		return if paused
		ctrlSocket.emit 'user_ctrl', ctrlData
		console.log "broadcasting state", ctrlData.position
	
	resume = ->
		paused = false
		broadcastUserState()

app.controller 'MapCtrl', ($scope, $timeout, $window, mapSocket, ctrlSocket) ->
	#SPEED = 40
	currentHeading = 0 # Due North
	peerDisconnected = true
	planeSprite = $window.jQuery('#plane')
	serverAircraftData = new Object()
	aircraftSprites = new Object()
	myAircraft = null

	$scope.onMapLoad = ->
		#startPositionBroadcast()
		google.maps.event.addListener $scope.map, "rightclick", (e) ->
			console.log "rightclick"
			new google.maps.Marker
				map: $scope.map
				position: e.latLng
			console.log "pos", e.latLng.toString()

	#do animatePlaneSprite = ->
		#return unless myAircraft?
		## ensure a smooth animation when the angles wrap around
		#nextHeading = myAircraft.heading
		#diff = Math.abs(nextHeading - currentHeading)
		#if diff > 180
			#if nextHeading > 0
				#currentHeading += 360
			#else
				#currentHeading += -360
		#tween = new TWEEN.Tween({angle: currentHeading}).to({angle: nextHeading}, 250)
		#tween.onUpdate ->
			#planeSprite.css
				#transform: "rotate(#{@angle}deg)"
		#tween.onComplete ->
			#currentHeading = @angle
			#animatePlaneSprite()
		#tween.start()

	#onSyncUI = (ctrlData) ->
		#angle = ctrlData.angle
		#nextHeading = (angle * 180/Math.PI) + 90
		#if peerDisconnected is true
			#peerDisconnected = false
			#updateMap()
	#ctrlSocket.on 'sync_ui', onSyncUI
	
	#updateMap = ->
		#curCenter = $scope.map.getCenter()
		#return unless curCenter?
		#$window.requestAnimationFrame updateMap unless peerDisconnected
		#newCenter = google.maps.geometry.spherical.computeOffset curCenter, SPEED, currentHeading
		#$scope.map.panTo newCenter
	
	#startPositionBroadcast = ->
		#lastBroadcastedPosition = null
		#do broadcastMapPosition = ->
			#$timeout broadcastMapPosition, 1000
			#return unless myAircraft?
			#curCenter = $scope.map.getCenter()
			#if !lastBroadcastedPosition? or !curCenter.equals(lastBroadcastedPosition)
				#lastBroadcastedPosition = curCenter
				#mapSocket.emit 'map_position_changed', 
					#code: myAircraft.code
					#position: [curCenter.lat(), curCenter.lng()]

	onPlanePositionChanged = (code, data) ->
		plane = getPlaneSpriteFor(data.code)
		plane.tween || animateSinglePlane(plane, data)

	mapSocket.on 'aircraftData', (aircraftData) ->
		serverAircraftData = aircraftData
		# TODO: make the user choose this
		onPlanePositionChanged(code, aircraft) for code, aircraft of serverAircraftData


	onPeerDisconnected = (data) ->
		peerDisconnected = true

	ctrlSocket.on 'peer_disconnected', onPeerDisconnected
	ctrlSocket.on 'peer_inactive', onPeerDisconnected

	followAircraft = (code) ->
		if myAircraft?
			planeSprite.hide 'fade'
			oldPlaneSprite = getPlaneSpriteFor myAircraft.code
			oldPlaneSprite.marker.setMap $scope.map
		sprite = aircraftSprites[code]
		sprite.marker.getMap().panTo sprite.marker.getPosition()
		sprite.marker.setMap null
		planeSprite.show 'fade'
		myAircraft = serverAircraftData[code]

	getPlaneSpriteFor = (code) ->
		sprite = aircraftSprites[code]
		return sprite if sprite?
		sprite =
			code: code
			marker: new google.maps.Marker
				map: $scope.map
				title: "F15 Strike Eagle"
		infoWindow = new google.maps.InfoWindow
			content: "<p>Code: #{code}</p>"
			maxWidth: 200
		infoWindow.open $scope.map, sprite.marker
		google.maps.event.addListener sprite.marker, "click", ->
			followAircraft code
		aircraftSprites[code] = sprite

	animateSinglePlane = (plane, planeServerData) ->
		plane.tween?.stop()
		next =
			lat: planeServerData.position[0]
			lng: planeServerData.position[1]
			heading: planeServerData.heading
		currentPos = plane.marker.getPosition()
		if currentPos?
			current =
				lat: currentPos.lat()
				lng: currentPos.lng()
				heading: currentHeading
			plane.tween = tween = new TWEEN.Tween(current)
			tween.to next, 2000
			tween.onUpdate ->
				plane.marker.setPosition new google.maps.LatLng(@lat, @lng)
				if (myAircraft? and planeServerData.code is myAircraft.code)
					planeSprite.css
						transform: "rotate(#{@heading}rad)"
					$scope.map.panTo plane.marker.getPosition()
			tween.onComplete ->
				plane.tween = null
				if (myAircraft? and planeServerData.code is myAircraft.code)
					currentHeading = next.heading
			tween.start()
		else
			plane.marker.setPosition new google.maps.LatLng(next.lat, next.lng)

