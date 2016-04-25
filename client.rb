#!/usr/bin/env ruby
require 'socket'

class chatClient
	def initialize(host, username)
		@socky = TCPSocket.open(host, 1337)
		@socky.puts "0 #{username}"
	end

	def clientize()
		while command = @socky.gets
			process(command)
		end
	end

	def process(command)
		@cmd = command.split(' ')
		num = @cmd.delete(0).to_i
		if num == 1
			msg = @cmd.join(' ')
			puts "#{msg}"
		elsif num == 2
			puts "Your username has been taken or otherwise sucks. Try again."
		elsif num == 5
			t = @cmd.delete(1)
			u = @cmd.delete(0)
			msg = @cmd.join(' ')
			puts "#{t} #{u}: #{msg}"
		elsif num == 6
			t = @cmd.delete(2)
			u = @cmd.delete(0)
			# srsly guys, totally not needed. we know who we are
			@cmd.delete(0)
			msg = @cmd.join(' ')
			puts "#{t} #{u} whispered: #{msg}"
		elsif num == 8
			@looping = 0
		end
	end

	def send(snd)

	end
end

@looping = 1

while @looping == 1
	cli = chatClient.new("yo").clientize()
	snd = gets
	if !snd.nil? || snd != ""
		cli.send(snd)
	end
end