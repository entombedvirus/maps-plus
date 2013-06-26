cluster = require 'cluster'

NUM_WORKERS = 1

if cluster.isMaster
	fs = require 'fs'
	pidfile = __dirname + '/pids/master.pid'
	fs.open pidfile, 'w', (err, fd) ->
		throw "Unable to create master pid file: #{err}" if err?
		fs.write fd, process.pid

	workerCount = 0

	cluster.on 'fork', (worker) ->
		console.log 'Worker', worker.id, "PID: ", worker.process.pid
		workerCount++

	cluster.on 'exit', (worker, code, signal) ->
		console.log 'worker died'
		workerCount--

	cluster.on 'listening', (worker) ->
		console.log 'worker', worker.id, "started listening"

	checkWorkerCount = ->
		cluster.fork() if workerCount < NUM_WORKERS
	setInterval checkWorkerCount, 1000 # prevent fork-bomb scenarios by setting the interval pretty high

else if cluster.isWorker
	require './app/index'