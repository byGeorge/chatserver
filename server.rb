#!/usr/bin/env ruby

require 'socket'
require 'time'

#start up a server
server = TCPServer.new 1337

class WebServer

	#initialize gets called at WebServer.new
	# @variable allows the thread to share data
	def initialize(client)

	end

	def serve()
		loop do
			#will read a line from the client request
			request = @client.gets
			
	    	#persistent connection will stay open until told to close
	    	break if request.include?("Connection: close")
	    end
	    #close the client. That's important.
	    @client.close 
	#rescue is one of the ways that Ruby handles exceptions
	rescue => e
		p e
		puts e.backtrace
	end

#run loop that listens for client requests
loop do
 	#service client on a new thread
 	Thread.start(server.accept) do |client|
 		begin 
    		WebServer.new(client).serve()
    	#this is here for error checking, please pay it no mind
   		rescue => e
   			#no really... p e sucks
    		p e
    		puts e.backtrace
    	end
    end
end

#don't leave the log file open!
$log.close
