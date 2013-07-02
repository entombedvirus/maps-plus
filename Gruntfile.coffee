'use strict'

path = require 'path'

module.exports = (grunt) ->
	# load all grunt tasks
	require('matchdep').filterDev('grunt-*').forEach grunt.loadNpmTasks

	appConfig =
		root: path.resolve(__dirname)
		server: path.resolve(__dirname + '/server')
		client: path.resolve(__dirname + '/public')
		dist: path.resolve(__dirname + '/dist')

	grunt.initConfig
		config: appConfig

		notify:
			watch:
				options:
					title: 'Task Complete!'
					message: 'auto-compilation complete'

		clean:
			server:
				src: ['server/**/*.{js,map}']
			client:
				src: ['public/angular/**/*.{js,map}', 'public/styles/*.css']
			dist:
				src: [appConfig.dist]

		copy:
			dist:
				files: [
					expand: true
					dot: true
					cwd: appConfig.root
					src: ['{server,public}/**/*.{js,json,css,jade,html,png,ico}']
					dest: appConfig.dist
				]

		coffee:
			client:
				options:
					sourceMap: true
				files: [
					expand: true
					cwd: appConfig.client
					src: '**/*.coffee'
					dest: appConfig.client
					ext: '.js'
				]
			server:
				options:
					sourceMap: true
				files: [
					expand: true
					cwd: appConfig.server
					src: '**/*.coffee'
					dest: appConfig.server
					ext: '.js'
				]

		ngmin:
			client:
				files: [
					expand: true
					cwd: appConfig.dist
					src: ['public/angular/**/*.js']
					dest: appConfig.dist
				]

		less:
			all:
				files: [
					src: appConfig.client + '/styles/*.less'
					dest: appConfig.client + '/styles/style.css'
				]

		watch:
			options:
				nospawn: true
			server:
				files: [appConfig.server + "/**/*.coffee"]
				tasks: ['coffee:server', 'notify:watch']
			client:
				files: [appConfig.client + "/angular/{*,}/*.coffee}"]
				tasks: ['coffee:client', 'notify:watch']
			css:
				files: [appConfig.client + "/styles/*.less"]
				tasks: ['less', 'notify:watch']

		nodemon:
			dev:
				options:
					file: path.join appConfig.server, 'index.js'
					watchedFolders: [appConfig.server]
					debug: true
					delay: 1

		concurrent:
			dev:
				tasks: ['nodemon', 'watch']
				options:
					logConcurrentOutput: true

	grunt.registerTask 'build', ['coffee', 'less']
	grunt.registerTask 'dev', ['clean', 'build', 'concurrent:dev']
	grunt.registerTask 'dist', ['clean', 'build', 'copy:dist', 'ngmin']

	grunt.registerTask 'default', ['dev']
