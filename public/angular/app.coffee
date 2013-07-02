"use strict"

###
	Declare app level module which depends on filters, services, and directives
###

deps = ["NetTalk.controllers", "NetTalk.filters", "NetTalk.services", "NetTalk.directives"]
angular.module(dep, []) for dep in deps

app = angular.module "NetTalk", deps.concat('ng')

app.config ($routeProvider) ->
	$routeProvider.when "/map", {templateUrl: "partials/map", controller: 'MapCtrl'}
	$routeProvider.when "/splash", {templateUrl: "partials/splash", controller: 'SplashCtrl'}
	$routeProvider.when "/controls", {templateUrl: "partials/controls", controller: 'UserControlsCtrl'}

	if /mobile/i.test window.navigator.userAgent
		$routeProvider.otherwise {redirectTo: "/splash"}
	else
		$routeProvider.otherwise {redirectTo: "/map"}

