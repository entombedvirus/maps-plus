cluster = require 'cluster'
fs = require('fs')

NUM_WORKERS = 1

# Let the OS do load balancing between node workers
cluster.schedulingPolicy = cluster.SCHED_NONE

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

	checkWorkerCount = ->
		cluster.fork() if workerCount < NUM_WORKERS
	setInterval checkWorkerCount, 1000 # prevent fork-bomb scenarios by setting the interval pretty high

else if cluster.isWorker
	require './index'