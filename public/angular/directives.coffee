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
					draggable: false
					disableDefaultUI: true
				)

				scope.$eval attrs.onload
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
app.directive 'onTouchMove', ->

	{
		restrict: 'A',
		
		compile: ->
			(scope, elem, attrs) ->
				elem.on 'touchmove mousemove', (e) ->
					e.preventDefault()
					cb = scope[attrs.onTouchMove]
					cb(e)
	}
