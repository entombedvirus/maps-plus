"use strict"

###
	Declare app level module which depends on filters, services, and directives
###

deps = ["NetTalk.controllers", "NetTalk.filters", "NetTalk.services", "NetTalk.directives"]
angular.module(dep, []) for dep in deps

angular.module("NetTalk", deps)
.config ["$routeProvider",
	($routeProvider) ->
		$routeProvider.when "/home", {templateUrl: "partials/home", controller: 'MapCtrl'}
		$routeProvider.when "/socket", {templateUrl: "partials/socket", controller: 'SocketCtrl'}
		$routeProvider.otherwise {redirectTo: "/home"}
]

