"use strict"

###
	Directives
###

app = angular.module("NetTalk.directives", ["ngResource"])

app.directive "appVersion", ["version", (version) ->
	(scope, elm, attrs) ->
		elm.text version
]

app.directive "googleMap", ->
	DEFAULT_ZOOM_LEVEL = 15
	GoogleMaps = google.maps
	GoogleMaps.visualRefresh = true

	{
		restrict: 'E',
		controller: ($scope, $element, $attrs, $q) ->
			mapLoad = $q.defer()

			@setMap = (map) ->
				@map = map
				mapLoad.resolve map

			@getMapPromise = ->
				mapLoad.promise

		compile: (elem, attrs, transclude) ->
			div = angular.element('<div id="mapView"/>')
			div.css({display: 'block'})
			#elem.replaceWith div
			elem.append div

			(scope, elem, attrs, controller) ->
				parts = attrs.center?.split ','
				if parts?
					lat = parseFloat(parts[0])
					lng = parseFloat(parts[1])
				else
					lat = 37.75549928195783
					lng = -122.45375823974608
				scope[attrs.name] = map = new GoogleMaps.Map(
					div[0]
				,
					center: new GoogleMaps.LatLng lat, lng
					zoom: (attrs.zoom? && parseInt attrs.zoom) || DEFAULT_ZOOM_LEVEL
					mapTypeId: GoogleMaps.MapTypeId.ROADMAP
					draggable: true
					disableDefaultUI: false
				)

				controller.setMap map
				scope.$eval attrs.onload

	}

app.directive "aircraft", ($log) ->
	{
		restrict: 'E',
		require: '^googleMap'
		scope:
			aircraftData: '='
		compile: ->
			class AircraftOverlay extends google.maps.OverlayView
				constructor: ->
					@aircrafts = new Object
					@parentDiv = angular.element("<div/>")
				updatePosition: (code, lat, lng, heading) ->
					aircraft = @aircrafts[code] ?=
						code: code
						lat: lat
						lng: lng
						shouldTween: false
					aircraft.heading = heading
					unless aircraft.icon?
						aircraft.icon = angular.element("<img class='aircraft'/>")
						aircraft.icon.appendTo @parentDiv
						aircraft.icon
						.attr(
							src: 'images/F15-Strike-Eagle-48px.png'
							width: '48px'
							height: '48px'
						).css(
							position: 'absolute'
							transition: 'transform 2s'
						)
						aircraft.infoWindow = new google.maps.InfoWindow
						  content: code
						aircraft.icon.on 'click', =>
							aircraft.infoWindow.open @getMap()

					if aircraft.shouldTween
						aircraft.tween?.stop()
						aircraft.tween = new TWEEN.Tween(
							aircraft
						).to(
							lat: lat
							lng: lng
						, 2000)
						aircraft.tween.onUpdate =>
							@updateSingleAircraftPosition aircraft
						aircraft.tween.start()
					else
						aircraft.shouldTween = true
						@updateSingleAircraftPosition @aircrafts[code]
					aircraft
				onAdd: ->
					panes = @getPanes()
					overlayLayer = panes.overlayMouseTarget
					@parentDiv.appendTo overlayLayer
				onRemove: ->
					@parentDiv.remove()
				draw: ->
					for code, aircraft of @aircrafts
						@updateSingleAircraftPosition aircraft
					null
				updateSingleAircraftPosition: (aircraft) ->
					projection = @getProjection()
					return unless projection?
					lat = aircraft.lat
					lng = aircraft.lng
					heading = aircraft.heading
					posLatLng = new google.maps.LatLng(lat, lng)
					posPixel = projection.fromLatLngToDivPixel posLatLng
					aircraft.icon.css
						top: (posPixel.y - aircraft.icon.height()/2) + 'px'
						left: (posPixel.x - aircraft.icon.width()/2) + 'px'
						transform: "rotate(#{heading}rad)"
					aircraft.infoWindow.setPosition posLatLng
					null

			overlay = new AircraftOverlay

			(scope, elem, attrs, googleMapCtrl) ->
				mapPromise = googleMapCtrl.getMapPromise()
				mapPromise.then (map) ->
					overlay.setMap map unless overlay.getMap()?
				scope.$watch 'aircraftData', ->
					return unless scope.aircraftData?
					scope.code = scope.aircraftData.code
					scope.lat = scope.aircraftData.lat
					scope.lng = scope.aircraftData.lng
					scope.heading = scope.aircraftData.heading
					overlay.updatePosition scope.code,
						parseFloat(scope.lat),
						parseFloat(scope.lng),
						parseFloat(scope.heading)
	}

app.directive "googleAnalytics", ->

	{
		restrict: "E",
		replace: true
		compile: (elem, attrs) ->
			script = angular.element """
				<script>
				(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
				(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
				m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
				})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

				ga('create', '#{attrs.id}', 'sentientagent.com');
				ga('send', 'pageview');

				</script>
			"""
			elem.replaceWith script
			script
	}

app.directive 'rotateControls', ($log, $document) ->
	{
		restrict: 'E',
		scope: {
			width: '@'
			height: '@',
			src: '@',
			value: '='
		},
		template: '<img ng-src="{{src}}" alt="" width="{{width}}" height="{{height}}"/>',
		link: (scope, elem, attrs) ->
			parentNode = elem.parent()
			curX = 0
			curY = 0
			centerX = 0
			centerY = 0
			newAngle = 0
			arrow = elem.find('img')

			do calculateCenter = ->
				arrowX = elem.offset().left
				arrowY = elem.offset().top
				centerX = arrowX + (elem.width() / 2)
				centerY = arrowY +  (elem.height() / 2)

			parentNode.on 'touchmove mousemove', (e) ->
				e.preventDefault()
				e = e.touches?[0] ? e
				curX = e.originalEvent.pageX
				curY = e.originalEvent.pageY
				scope.value = newAngle = Math.atan2(curY - centerY, curX - centerX) + Math.PI/2
				arrow.css
					transform: "rotate(#{newAngle}rad)"

			$document.on 'orientationchange', (e) ->
				$log.info "orientationchange event fired"
				calculateCenter()
	}