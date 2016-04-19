#!/usr/bin/env ruby

require 'socket'
require 'time'

class ChatServer

	#initialize gets called at ChatServer.new(client)
	# @variable allows the thread to share data
	def initialize(client)
		#makes a variable for the thread that can be accessed for all methods
		@client = client
	end

	def serve()
		#the first request should be a request for a user name 
		#the server should close the thread if it's not
		request = @client.gets
		get_user_name(request)
		loop do
			#will read a line from the client request
			request = @client.gets.split(' ')

	    	#persistent connection will stay open until told to close
	    	break if request[0].eql?("7")

	    	process(request)
	    end
	    # send a disconnect message
	    @client.puts("8")
	    # send a message to everyone
		$users.values.each do |user|
			user.puts("9 #{@user} #{msg}")
		end
	    # remove the client from the list
	    $users.delete(@user)
	    #close the client. That's important.
	    @client.close 
	#rescue is one of the ways that Ruby handles exceptions
	rescue => e
		# in this case the client probably closed the chat unexpectedly
		$users.values.each do |user|
			user.puts("9 #{@user}")
		end
	    # remove the client from the list
	    $users.delete(@user)
	    #close the client. That's important.
	    @client.close 
	end

	def get_user_name(request)
		req = request.split(' ')
		# check for properly phrased request
		if req[0] == "0"
			# check if user name exists
			if $users.keys.include?(req[1])
				@client.puts("2 /r/n")
				@client.close
			else
				# add client to list 
				$users.store(req[1], @client)
				@user = req[1]
				$users.values.each do |user|
					user.puts("10 #{@user}")
				end
				# create welcome message text
				msg = "1 "
				msg += $users.keys.sort!.join(',')
				msg += " You have successfully logged in. Look how special you are!"
				# and send welcome message
				@client.puts(msg)
			end
		else
			@client.puts("2 /r/n")
			@client.close
		end
	end #end get_user_name

	def process(request)
		# if this is a general message
		if request[0] == "3"
			# now we know the request type and no longer need it
			request.delete_at(0)
			# put the message back together
			msg = request.join(' ')
			# send the message to everyone
			$users.values.each do |user|
				user.puts("5 #{Time.now.gmtime.strftime("%Y:%m:%d:%H:%M:%S")} #{msg}")
			end
		# if this is a private message
		elsif request[0] == "4"
			# now we know the request type and no longer need it
			request.delete_at(0)
			# save the user names and deletes them from the array
			msg_from = request.delete_at(0)
			msg_to = request.delete_at(0)
			# put the message back together
			msg = request.join(' ')
			# does the user exists ? if yes, send the message : if not, don't do anything
			$users.key?(msg_to) ? $users.fetch(msg_to).puts("6 #{msg_from} #{msg_to} #{Time.now.gmtime.strftime("%Y:%m:%d:%H:%M:%S")} #{msg}") : ""
		end
		#process(request) won't do anything if any other number has been entered
	end
end # end class chatserver

#start up a server
server = TCPServer.new 1337

#initialize a hash with the username as key and the thread as the value
$users = Hash.new

#run loop that listens for client requests
loop do
 	#service client on a new thread
 	Thread.start(server.accept) do |client|
 		begin 
    		ChatServer.new(client).serve()
    	#this is here for error checking, please pay it no mind
   		rescue => e
   			#no really... p e sucks
    		p e
    		puts e.backtrace
    	end
    end
end
