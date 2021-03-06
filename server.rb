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
		if @client.closed?
			p "username request denied!"
		else
			loop do
				#will read a line from the client request
				request = @client.gets.split(' ')
				#process the request
				process(request)
			    #persistent connection will stay open until told to close
			    break if request[0].eql?("7")
			end
		end
	end

	def get_user_name(request)
		req = request.split(' ')
		# check for properly phrased request
		if req[0] == "0"
			exists = 0
			# check if user name exists, regardless of capitalization
			$users.each_key { | key | exists = 1 if key.downcase == req[1].downcase }
			if exists == 1
				#this username has a space, so will only happen if there's a login failure
				@user = "login failure"
				@client.puts("2")
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
			@client.puts("2")
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
			if msg_from == @user
				msg_to = request.delete_at(0)
				# put the message back together
				msg = request.join(' ')
				# does the user exists ? if yes, send the message : if not, don't do anything
				$users.key?(msg_to) ? $users.fetch(msg_to).puts("6 #{msg_from} #{msg_to} #{Time.now.gmtime.strftime("%Y:%m:%d:%H:%M:%S")} #{msg}") : ""
			else
				# if the sender is trying to pretend to be someone else
				@client.puts("6 server #{@user} You're not #{msg_from}! LIAR LIAR PANTS ON FIRE!")
			end
		elsif request[0] == "7"
			@client.puts("8")
			# remove the client from the list
	    	$users.delete(@user)
			# send a message to everyone else
			$users.values.each do |user| 
				user.puts("9 #{@user}")
	    	end
	    	#close the client. That's important.
	    	@client.close 
		end
		#process(request) won't do anything if any other number has been entered
	end # end process
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
    	#unexpected closure will start the rescue block
    	rescue
    		#closes the socket
    		client.close
    		dud = "unknown"
    		#checks each pair for the closed socket
    		$users.each_pair do |key, value| 
    			dud = key if value.closed? 
    		end
    		if dud != "unknown"
	    		# remove the client from the list
		    	$users.delete(dud)
				# send a message to everyone else
				$users.values.each do |user| 
					user.puts("9 #{dud}")  
				end
	    	end
    	end
    end
end
