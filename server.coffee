cluster = require 'cluster'
fs = require('fs')

NUM_WORKERS = 1

if cluster.isMaster
	workerCount = 0

	cluster.on 'fork', (worker) ->
		console.log 'Worker', worker.id, "PID: ", worker.process.pid
		workerCount++

	cluster.on 'exit', (worker, code, signal) ->
		console.log 'worker died'
		workerCount--

	cluster.on 'listening', (worker) ->
		console.log 'worker', worker.id, "started listening"

	pidfile = __dirname + '/pids/master.pid'
	if fs.existsSync pidfile
		try
			oldMasterPid = fs.readFileSync pidfile
			process.kill oldMasterPid
		catch
			# do nothing

	fs.open pidfile, 'w', (err, fd) ->
		throw "Unable to create master pid file: #{err}" if err?
		fs.write fd, process.pid

	checkWorkerCount = ->
		cluster.fork() if workerCount < NUM_WORKERS
	setInterval checkWorkerCount, 1000 # prevent fork-bomb scenarios by setting the interval pretty high

else if cluster.isWorker
	require './app/index'