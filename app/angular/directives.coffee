"use strict"

###
  Directives
###

app = angular.module("NetTalk.directives", ["ngResource"])

app.directive "appVersion", ["version", (version) ->
  (scope, elm, attrs) ->
    elm.text version
]

app.directive "googleMaps", ->
	DEFAULT_ZOOM_LEVEL = 15
	GoogleMaps = google.maps
	GoogleMaps.visualRefresh = true

	{
		restrict: 'E',
		#replace: true,
		compile: (elem, attrs, transclude) ->
			div = angular.element('<div id="mapView"/>')
			div.css({display: 'block'})
			#elem.replaceWith div
			elem.append div

			(scope, elem, attrs) ->
				parts = attrs.center?.split ','
				if parts?
					lat = parseFloat(parts[0])
					lng = parseFloat(parts[1])
				else
					lat = 37.75549928195783
					lng = -122.45375823974608
				map = scope[attrs.name]  = new GoogleMaps.Map(
					div[0]
				,
					center: new GoogleMaps.LatLng lat, lng
					zoom: (attrs.zoom? && parseInt attrs.zoom) || DEFAULT_ZOOM_LEVEL
					mapTypeId: GoogleMaps.MapTypeId.ROADMAP
				)

				scope.$eval(attrs.onload) if attrs.onload?
	}
