##########################################################################
# Postbot 4.0
# (c) 2007 Michael 'sECuRE' Stapelberg
##########################################################################

putlog "Postbot 4.0 by sECuRE@twice-irc.de loading..."

##########################################################################
# Configuration
##########################################################################

# token of this bot (unique identifier)
set token "foo"
# URL to the folder where the Postbot-server-scripts are located
set pb_url "http://localhost:5005/postbot"
set pb_user ""
set pb_pass ""
# Timeout for communicating with the server (in miliseconds), default 10s
set http_timeout 10000
# Channels to which the bot is allowed to post
# NOTE: You have to configure these in the WBB Administration Panel aswell
set channels(0) "#hc"
set channels(1) "#bar"
# Administration-Channels (for new registrations, ip addresses and further
# administrative information ONLY!)
set adminchannels(0) "#admin"

# We need the http-package to communicate with the server
package require http
# Base64 to encode the password
package require base64

# comment the next two lines if you don't need HTTPS and don't want to install
# the tcltls-package. If you need it, use apt-get install tcltls
package require tls
::http::register https 443 ::tls::socket

# We need tclxml for parsing the RSS feed
# NOTE: If you get error messages about this, install packet tclxml via
# apt-get install tclxml on Debian, emerge tclxml on gentoo or
# download/install manually from http://tclxml.sourceforge.net/
package require xml

##########################################################################
# DON'T TOUCH THE FOLLOWING CODE!
##########################################################################

# I know, the XML-parsing-code is quite ugly, if someone has a better
# solution, not requiring extra packets, tell me please :)

bind pub - !topposter pb_topposter
bind pub - !latest pb_latest
bind pub - !online pb_online
bind pub - !boardseen pb_seen
bind pub - !boardsearch pb_search

set xml_doparse 0
set xml_at ""
set handler ""
set handlerarg ""
set last_id 0

proc buildProxyHeaders {username password} {
	return [list "Authorization" [concat "Basic" [base64::encode $username:$password]]]
}

proc xml_start {name attlist args} {
	global xml_at xml_doparse xml_inel
	if {$xml_doparse == 1} {
		set xml_at $name
	}
	if {$name == "item"} {
		set xml_doparse 1
	}
	set xml_inel 1
}

proc xml_cdata {data} {
	global xml_el xml_at xml_doparse xml_inel
	if {$xml_doparse == 1 && $xml_inel == 1} {
		set xml_el($xml_at) $data
	}
}

proc xml_end {name args} {
	global xml_el xml_doparse xml_inel handler handlerarg
	if {$name == "item"} {
		if {$xml_doparse == 1} {
			if {$handler == "putserv"} {
				$handler [subst $handlerarg]
			} else {
				$handler $handlerarg
			}
		}
		set xml_doparse 0
	} elseif {$name == "error"} {
		putserv "PRIVMSG $handlerarg :ERROR: $xml_el(error)"
		set xml_doparse 0
	}
	set xml_inel 0
}

proc get_destination {} {
	global xml_el channels
	if {$xml_el(destination) == "*"} {
		array set dest [array get channels]
	} else {
		array set dest {}
		set destnum 0
		set requested_destination [split $xml_el(destination) " "]
		foreach destination $requested_destination {
			set found 0
			foreach {el channel} [array get channels] {
				if {$channel == $destination} {
					set found 1
					break
				}
			}
			if {$found == 1} {
				set dest($destnum) $destination
				incr destnum
			}
		}
	}
	return [array get dest]
}

proc is_botchannel {chan} {
	global channels
	set found 0
	foreach {el channel} [array get channels] {
		if {$channel == $chan} {
			set found 1
			break
		}
	}
	return $found
}

#
# Fetches and parses the given URL from the server
#
proc parse_url {url} {
	global pb_url pb_user pb_pass http_timeout xml_el
	if {[llength [array names xml_el]] > 0} {
		unset xml_el
	}
	set path "$pb_url/$url"
		putlog "opening $path"
#TODO
#-headers [buildProxyHeaders $pb_user $pb_pass]
	if {[catch {set token [::http::geturl $path -timeout $http_timeout]}]} {
		putlog "\[Postbot\] ERROR: Could not fetch $path"
		return
	}
	if {[::http::status $token] != "ok" || [::http::ncode $token] != "200"} {
		putlog "\[Postbot\] ERROR: Server returned [::http::code $token]"
		putlog "\[Postbot\] Requested URL was $path"
		putlog "\[Postbot\] Check \$pb_url setting in postbot.tcl"
		return
	}
	upvar #0 $token state
	set parser [::xml::parser -elementstartcommand xml_start -characterdatacommand xml_cdata -elementendcommand xml_end]
	$parser parse $state(body)
	::http::cleanup $token
}

proc put_post {dest} {
	global xml_el
	if {$xml_el(isReply) == 1} {
		putserv "PRIVMSG $dest :\[$xml_el(time)\] $xml_el(author) antwortet auf \"$xml_el(title)\" in $xml_el(board)"
	} else {
		putserv "PRIVMSG $dest :\[$xml_el(time)\] $xml_el(author) posted: \"$xml_el(title)\" in $xml_el(board)"
	}
	putserv "PRIVMSG $dest :\[$xml_el(time)\] URL: $xml_el(link)"
}

#
# Posts the contents of xml_el into the specified channels
#
proc put_posts {dest} {
	global xml_el last_id
	foreach {el channel} [get_destination] {
		put_post $channel
	}
	if {$xml_el(postID) > $last_id} {
		set last_id $xml_el(postID)
	}
}

proc pb_topposter {nick host handle chan text} {
	global handler handlerarg token
	if {[is_botchannel $chan]} {
		set handler "putserv"
		set handlerarg "PRIVMSG $chan :\$xml_el(author) mit \$xml_el(title)"
		putserv "PRIVMSG $chan :Die Benutzer mit den meisten Posts:"
		parse_url "topposter.php?token=$token"
	}
}

proc pb_latest {nick host handle chan text} {
	global handler handlerarg token
	if {[is_botchannel $chan]} {
		set handler put_post
		set handlerarg $chan
		parse_url "getposts.php?token=$token&is_latest=1"
	}
}

proc pb_online {nick host handle chan text} {
	global handler handlerarg token
	if {[is_botchannel $chan]} {
		set handler "putserv"
		set handlerarg "PRIVMSG $chan :Momentan online: \$xml_el(title)"
		parse_url "online.php?token=$token"
	}
}

proc pb_seen {nick host handle chan text} {
	global handler handlerarg token
	if {[is_botchannel $chan]} {
		if {$text == ""} {
			putserv "PRIVMSG $chan :Syntax: !boardseen <username>"
		} else {
			set handler "putserv"
			set handlerarg "PRIVMSG $chan :\$xml_el(author) wurde zuletzt gesehen am: \$xml_el(title)"
			parse_url "seen.php?token=$token&username=$text"
		}
	}
}

proc pb_search {nick host handle chan text} {
	global handler handlerarg token
	if {[is_botchannel $chan]} {
		if {$text == ""} {
			putserv "PRIVMSG $chan :Syntax: !boardsearch <term> ..."
		} else {
			set handler put_post
			set handlerarg $chan
			parse_url "getposts.php?token=$token&search_terms=$text"
		}
	}
}

proc pb_timer {} {
	global handler handlerarg token last_id
	utimer 30 "pb_timer"
	set handler "put_posts"
	set handlerarg ""
	parse_url "getposts.php?token=$token&lastpost=$last_id"
}

proc timerexists {command} {
	foreach i [utimers] {
		if {![string compare $command [lindex $i 1]]} then {
			return [lindex $i 2]
		}
	}
	return
}


if {[timerexists "postbot"] == ""} {
	putlog "Launching postbot timer..."
	utimer 30 "pb_timer"
}
