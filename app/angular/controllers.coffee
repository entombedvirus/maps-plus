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
	plane = $window.jQuery('#plane')

	do animatePlane = ->
		# ensure a smooth animation when the angles wrap around
		diff = Math.abs(nextHeading - currentHeading)
		if diff > 180
			if nextHeading > 0
				currentHeading += 360
			else
				currentHeading += -360
		tween = new TWEEN.Tween({angle: currentHeading}).to({angle: nextHeading}, 250)
		tween.onUpdate ->
			plane.css
				transform: "rotate(#{@angle}deg)"
		tween.onComplete ->
			currentHeading = @angle
			animatePlane()
		tween.start()

	onSyncUI = (ctrlData) ->
		angle = ctrlData.angle
		nextHeading = (angle * 180/Math.PI) + 90
		if peerDisconnected is true
			peerDisconnected = false
			updateMap()
	
	updateMap = ->
		curCenter = $scope.map.getCenter()
		return unless curCenter?
		$window.requestAnimationFrame updateMap unless peerDisconnected
		newCenter = google.maps.geometry.spherical.computeOffset curCenter, SPEED, currentHeading
		$scope.map.panTo newCenter

	onPeerDisconnected = (data) ->
		peerDisconnected = true

	Socket.ctrl.on 'sync_ui', onSyncUI
	Socket.ctrl.on 'peer_disconnected', onPeerDisconnected
	Socket.ctrl.on 'peer_inactive', onPeerDisconnected

