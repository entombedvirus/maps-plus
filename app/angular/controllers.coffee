"use strict"

###
	Controllers
###

app = angular.module('NetTalk.controllers')

app.controller 'AppCtrl', (Animation) ->
	Animation.start()

app.controller 'UserControlsCtrl', ($scope, $timeout, $window, Socket) ->
	curX = 0
	curY = 0
	curAngle = 0
	arrow = angular.element document.getElementById('arrow')
	arrowX = arrow.offset().left
	arrowY = arrow.offset().top
	centerX = arrowX + (arrow.width() / 2)
	centerY = arrowY +  (arrow.height() / 2)
	lastActivityTimestamp = new Date().getTime()
	paused = false

	timer = null
	do startIdleTimer = ->
		idleTime = (new Date()).getTime() - lastActivityTimestamp
		if idleTime > 5000
			timer = null
			paused = true
			Socket.ctrl.emit 'peer_inactive'
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
		newAngle = Math.atan2(curY - centerY, curX - centerX)

		# ensure a smooth animation when the angles wrap around
		diff = Math.abs(newAngle - curAngle)
		if diff > Math.PI
			if newAngle > 0
				curAngle += 2 * Math.PI
			else
				curAngle += -2 * Math.PI
		tween = new TWEEN.Tween({angle: curAngle}).to({angle: newAngle}, 25)
		tween.onUpdate ->
			arrow.css
				transform: "rotate(#{@angle}rad)"
		tween.onComplete ->
			curAngle = newAngle
			animateArrow()
		tween.start()

	do broadcastUserState = ->
		return if paused
		ctrlData =
			angle: curAngle
		Socket.ctrl.emit 'user_ctrl', ctrlData
		console.log "broadcasting state", ctrlData
		$timeout broadcastUserState, 250
	
	resume = ->
		paused = false
		broadcastUserState()


app.controller 'SocketCtrl', ($scope, Socket) ->
	$scope.response = "waiting..."
	Socket.chat.on "pong", (data) ->
		console.log "got pong msg", data
		$scope.response = data.data

	$scope.ping = ->
		Socket.chat.emit("ping", {})

app.controller 'MapCtrl', ($scope, $timeout, $window, Socket) ->
	SPEED = 40
	currentHeading = 0 # Due North
	nextHeading = 0
	peerDisconnected = true
	planeSprite = $window.jQuery('#plane')
	planes = new Object()

	$scope.onMapLoad = ->
		startPositionBroadcast()
		google.maps.event.addListener $scope.map, "rightclick", (e) ->
			console.log "rightclick"
			new google.maps.Marker
				map: $scope.map
				position: e.latLng
			console.log "pos", e.latLng.toString()

	do animatePlaneSprite = ->
		# ensure a smooth animation when the angles wrap around
		diff = Math.abs(nextHeading - currentHeading)
		if diff > 180
			if nextHeading > 0
				currentHeading += 360
			else
				currentHeading += -360
		tween = new TWEEN.Tween({angle: currentHeading}).to({angle: nextHeading}, 250)
		tween.onUpdate ->
			planeSprite.css
				transform: "rotate(#{@angle}deg)"
		tween.onComplete ->
			currentHeading = @angle
			animatePlaneSprite()
		tween.start()

	onSyncUI = (ctrlData) ->
		angle = ctrlData.angle
		nextHeading = (angle * 180/Math.PI) + 90
		if peerDisconnected is true
			peerDisconnected = false
			updateMap()
	Socket.ctrl.on 'sync_ui', onSyncUI
	
	updateMap = ->
		curCenter = $scope.map.getCenter()
		return unless curCenter?
		$window.requestAnimationFrame updateMap unless peerDisconnected
		newCenter = google.maps.geometry.spherical.computeOffset curCenter, SPEED, currentHeading
		$scope.map.panTo newCenter
	
	startPositionBroadcast = ->
		lastBroadcastedPosition = null
		do broadcastMapPosition = ->
			$timeout broadcastMapPosition, 1000
			curCenter = $scope.map.getCenter()
			if !lastBroadcastedPosition? or !curCenter.equals(lastBroadcastedPosition)
				lastBroadcastedPosition = curCenter
				Socket.map.emit 'map_position_changed', [curCenter.lat(), curCenter.lng()]

	onPlanePositionChanged = (data) ->
		plane = getPlaneFor(data.client_id)
		plane.position =
			lat: data.position[0]
			lng: data.position[1]
		plane.tween || animateSinglePlane(plane)
	Socket.map.on 'plane_position_changed', onPlanePositionChanged

	onPeerDisconnected = (data) ->
		peerDisconnected = true

	Socket.ctrl.on 'peer_disconnected', onPeerDisconnected
	Socket.ctrl.on 'peer_inactive', onPeerDisconnected

	getPlaneFor = (client_id) ->
		planes[client_id] ?=
			client_id: client_id
			speed: 8
			marker: new google.maps.Marker
				map: $scope.map

	animateSinglePlane = (plane) ->
		plane.tween?.stop()
		currentPos = plane.marker.getPosition()
		if currentPos?
			currentPos =
				lat: currentPos.lat()
				lng: currentPos.lng()
			plane.tween = tween = new TWEEN.Tween(currentPos)
			tween.to plane.position, 5000/plane.speed
			tween.onUpdate ->
				plane.marker.setPosition new google.maps.LatLng(@lat, @lng)
			tween.onComplete ->
				plane.tween = null
			tween.start()
		else
			plane.marker.setPosition new google.maps.LatLng(plane.position.lat, plane.position.lng)

